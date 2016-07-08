# Iterates through our SF objects and writes statistics to them from our course
# and period data.  Finds periods in courses that don't yet have an assigned
# SF object and finds or makes one for them.
#
# Notes:
#   1. In this file, "ar" stands for AttachedRecord, not ActiveRecord
#   2. This file cannot be a Lev routine because it can create SF objects
#      and we don't want a transaction that rolls back local objects because
#      the SF objects cannot be rolled back.

class UpdateSalesforceCourseStats

  def self.call(handle_orphaned_periods: true, write_stats: true)
    new.call(handle_orphaned_periods: handle_orphaned_periods, write_stats: write_stats)
  end

  def call(handle_orphaned_periods: true, write_stats: true)
    log { "Starting..." }

    organizer = initialize_organizer
    attach_orphaned_periods_to_sf_objects(organizer) if handle_orphaned_periods
    write_stats_to_salesforce(organizer) if write_stats

    log { "Finished." }

    outputs
  end

  def attached_records
    @attached_records ||= Salesforce::AttachedRecord.preload(:salesforce_objects)
  end

  def initialize_organizer
    organizer = Organizer.new

    # Loop through known AR/course/period relations and add them to the organizer

    attached_records.each do |ar|
      case ar.attached_to_class_name
      when "Entity::Course"
        organizer.set_course_id(salesforce_object: ar.salesforce_object,
                                course_id: ar.attached_to_id)
      when "CourseMembership::Models::Period"
        organizer.add_period_id(salesforce_object: ar.salesforce_object,
                                period_id: ar.attached_to_id)
      end
    end

    # Load all of the model data at once (prevent N+1 queries later)

    courses = Entity::Course.where(id: organizer.course_ids)
                            .preload([:teachers,
                                      { periods_with_deleted: :latest_enrollments_with_deleted }])

    # Go through each course object and its period objects, telling the organizer about them (so it
    # can do efficient lookups later).  For all periods without an AR in the organizer, add them
    # as orphans so that other code can (at its discretion) build new ARs for them.

    courses.each do |course|
      organizer.remember_course(course)
      periods = course.periods_with_deleted

      periods.each do |period|
        organizer.remember_period(period)
        organizer.add_orphan_period(period) if organizer.no_salesforce_object_for_period?(period)
      end
    end

    organizer
  end

  def attach_orphaned_periods_to_sf_objects(organizer)
    # Find an appropriate SF object for each period or make one then attach it.

    organizer.orphaned_periods.each do |period|

      # Figure out what SF objects we already have for this period's course

      course = organizer.get_course(period.entity_course_id)
      course_sf_objects = organizer.get_sf_objects(course_id: course.id)

      if course_sf_objects.none?
        notify("No Salesforce object available for period #{period.id} stats reporting",
               period: period.id)
        next
      end

      # Narrow down those SF objects to those that work for this period, reusing if
      # there is one or making if there aren't any.
      #
      # Note that this code is where we have a HACK to keep stats from different
      # semesters in different SF objects while allowing teachers to reuse one
      # Course from semester to semester.  We guess which TermYear periods belong
      # to based on their creation date (assuming that periods created towards the end
      # of the semester are intended to be used in the following semester).  Hopefully
      # in the future some of this code will go away or become unused when we prohibit
      # teachers from reusing Courses across semesters.

      target_term_year = Salesforce::Remote::TermYear.guess_from_created_at(period.created_at)
      eligible_sf_objects = course_sf_objects.select do |sf|
        sf.term_year_object == target_term_year
      end

      if eligible_sf_objects.many?
        notify("Multiple Salesforce records are eligible for to period #{period.id} stats reporting",
               period: period.id, eligible_sf_objects: eligible_sf_objects.map(&:id))
        next
      end

      sf_object_to_use = nil

      if eligible_sf_objects.one?
        # there is one, just use it
        sf_object_to_use = eligible_sf_objects.first
      else
        # no eligible objects, make a new one based on ANY existing SF obj for course
        begin
          sf_object_to_use =
            Salesforce::RenewOsAncillary.call(based_on: course_sf_objects.first,
                                              renew_for_term_year: target_term_year)
        rescue Salesforce::OsAncillaryRenewalError => e
          notify("Salesforce record renewal error for period #{period.id}: #{e.message}")
          next
        end
      end

      # Attach the SF object to the period and course and remember these
      # attachments in the organizer

      Salesforce::AttachRecord[record: sf_object_to_use, to: period]
      organizer.add_period_id(salesforce_object: sf_object_to_use, period_id: period.id)

      if !course_sf_objects.map(&:id).include?(sf_object_to_use.id)
        Salesforce::AttachRecord[record: sf_object_to_use, to: course]
        organizer.set_course_id(salesforce_object: sf_object_to_use, course_id: course.id)
      end

    end
  end

  def write_stats_to_salesforce(organizer)
    num_errors = 0
    num_updates = 0
    num_records = 0

    organizer.each do |salesforce_object, course, periods|
      an_error_occurred = false
      salesforce_object.error = nil

      begin
        salesforce_object.num_teachers = course.teachers.length
        salesforce_object.num_students = periods.flat_map(&:latest_enrollments_with_deleted).length
        salesforce_object.num_sections = periods.length
      rescue Exception => e
        an_error_occurred = true
        salesforce_object.error = "Unable to update stats: #{e.message}" if salesforce_object.present?
        OpenStax::RescueFrom.perform_rescue(e)
      end

      begin
        if salesforce_object.present? && salesforce_object.changed?
          salesforce_object.save
          num_updates += 1
        end
      rescue Exception => e
        an_error_occurred = true
        OpenStax::RescueFrom.perform_rescue(e)
      end

      num_records += 1
      num_errors += 1 if an_error_occurred
    end

    log {
      "Wrote stats for #{num_records} SF record(s); Made #{num_updates} successful " +
      "update(s); #{num_errors} error(s) occurred."
    }

    outputs[:num_records] = num_records
    outputs[:num_errors] = num_errors
    outputs[:num_updates] = num_updates
  end

  # A helper class that (1) keeps track of relationships between courses, periods, and their
  # attached salesforce objects and (2) provides helper methods for examining and accessing those
  # relationships
  #
  class Organizer
    def initialize
      @tuples_by_sf_object_id = {}
      @tuples_by_period_id = {}
      @tuples_by_course_id = {}
      @period_id_to_period_map = {}
      @course_id_to_course_map = {}
      @orphaned_periods = Set.new
    end

    def add_period_id(salesforce_object:, period_id:)
      tuple = get_by_sf_object(salesforce_object)
      tuple.add_period_id(period_id)
      @tuples_by_period_id[period_id] = tuple
    end

    def set_course_id(salesforce_object:, course_id:)
      tuple = get_by_sf_object(salesforce_object)
      tuple.course_id = course_id
      (@tuples_by_course_id[course_id] ||= []).push(tuple)
    end

    def get_sf_objects(course_id:)
      get_by_course_id(course_id).map(&:salesforce_object)
    end

    def no_salesforce_object_for_period?(period)
      @tuples_by_period_id[period.id].nil?
    end

    def add_orphan_period(period)
      @orphaned_periods.add(period)
    end

    def remember_period(period)
      @period_id_to_period_map[period.id] = period
    end

    def remember_course(course)
      @course_id_to_course_map[course.id] = course
    end

    def get_course(course_id)
      @course_id_to_course_map[course_id]
    end

    def course_ids
      @tuples_by_course_id.keys
    end

    def orphaned_periods
      @orphaned_periods.to_a
    end

    def each(&block)
      @tuples_by_sf_object_id.each do |_, tuple|
        sf_object = tuple.salesforce_object
        course = @course_id_to_course_map[tuple.course_id]
        periods = tuple.period_ids.map{|period_id| @period_id_to_period_map[period_id]}

        block.call(sf_object, course, periods)
      end
    end

    def size
      @tuples_by_sf_object_id.size
    end

    private

    class Tuple
      attr_reader :salesforce_object
      attr_reader :period_ids
      attr_reader :course_id

      def initialize(salesforce_object)
        @salesforce_object = salesforce_object
        @course_id = nil
        @period_ids = []
      end

      def add_period_id(period_id)
        @period_ids.push(period_id)
      end

      def course_id=(val)
        raise "course_id can only be set once" if @course_id.present?
        @course_id = val
      end
    end

    def get_by_sf_object(sf_object)
      @tuples_by_sf_object_id[sf_object.id] ||= Tuple.new(sf_object)
    end

    def get_by_course_id(course_id)
      @tuples_by_course_id[course_id]
    end
  end

  def outputs
    @outputs ||= OpenStruct.new
  end

  def notify(message, details={})
    WarningMailer.log_and_deliver({message: message, details: details})
  end

  def log(&block)
    Rails.logger.info { "[UpdateSalesforceCourseStats] #{block.call}" }
  end

end
