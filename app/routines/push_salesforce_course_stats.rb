class PushSalesforceCourseStats

  def self.call
    new.call
  end

  def initialize(allow_error_email:)
    @allow_error_email = allow_error_email
    @errors = []
  end

  def call
    log { "Starting..." }

    applicable_courses.find_each do |course|
      call_for_course(course)
    end

    notify_errors

    log { "Finished." }
  end

  def call_for_course(course)
    begin
      attached_record = courses_to_attached_records[course]
      os_ancillary = attached_record.try(:salesforce_object)

      # If no OSA, try to make one

      if os_ancillary.nil?
        # First figure out which SF Contact the OSA would hang off of

        sf_contact_id = best_sf_contact_id_for_course(course)
        if sf_contact_id.nil?
          error!(message: "No teacher SF contact for course #{course.id}")
          return
        end

        # Next see if there's an appropriate IndividualAdoption; if not, make one.

        individual_adoption_criteria = {
          contact_id: sf_contact_id,
          book_name: based_on_opportunity.book_name,
          term_year: salesforce_term_year_for_course(course)
        }

        candidate_individual_adoptions = Salesforce::Remote::IndividualAdoption
                                           .where(individual_adoption_criteria)
                                           .to_a

        if candidate_individual_adoptions.size > 1
          error!(message: "Too many IndividualAdoptions matching #{individual_adoption_criteria}",
                 course: course)
          return
        end

        individual_adoption =
          candidate_individual_adoptions.first ||
          begin
            Salesforce::Remote::IndividualAdoption.new(individual_adoption_criteria).tap do |ia|
              if !ia.save
                error!(message: "Could not save new IndividualAdoption for inputs " \
                                "#{individual_adoption_criteria}; errors: " \
                                "#{ia.errors.full_messages.join(', ')}",
                       course: course)
                return
              end
            end
          end

        # Now see if there's an appropriate OSA on the IA; if not, make one.
        # Attach the OSA to the course so we can just use it next time.

        os_ancillary_criteria = {
          individual_adoption_id: individual_adoption.id,
          product: course.is_concept_coach ? "Concept Coach" : "Tutor"
        }

        candidate_os_ancillaries = Salesforce::Remote::OsAncillary.where(os_ancillary_criteria).to_a

        if candidate_os_ancillaries.size > 1
          error!(message: "Too many OsAncillaries matching #{os_ancillary_criteria}", course: course)
          return
        end


        os_ancillary = candidate_os_ancillaries.first ||
          begin
            Salesforce::Remote::OsAncillary.new(os_ancillary_criteria).tap do |osa|
              if !osa.save
                error!(message: "Could not save new OsAncillary for inputs #{os_ancillary_criteria}; " \
                                "errors: #{osa.errors.full_messages.join(', ')}",
                       course: course)
                return
              end

              # Values in the OSA that are derived from other places in SF, e.g. `TermYear`,
              # cannot be set when creating the record.  Instead of manually setting them
              # here, just reload the object from SF so that we know any derived fields are
              # populated.
              osa.reload
            end
          end
      end

      push_stats(course, os_ancillary)

    rescue StandardError => ee
      error!(exception: ee, course: course)
    end
  end

  def salesforce_term_year_for_course(course)
    raise "not yet implemented"
  end

  def push_stats(course, sf_object)
    raise "not yet implemented"
  end

  def best_sf_contact_id_for_course(course)
    raise "not yet implemented"
  end

  def applicable_courses
    # Just get courses made in the era of not reusing courses semester to semester
    @courses ||= CourseProfile::Models::Course.where{created_at.gt look_at_courses_after}
  end

  def look_at_courses_after
    Chronic.parse("12/26/2016")
  end

  def courses_to_attached_records
    @courses_to_attached_records ||= begin
      ars = Salesforce::AttachedRecord
              .preload(:salesforce_objects)
              .select{|ar| ar.attached_to_class_name == "CourseProfile::Models::Course"}
      ars.map{|ar| [ar.attached_to, ar]}.to_h
    end
  end

  def log(&block)
    Rails.logger.info { "[#{class.name}] #{block.call}" }
  end

  def error!(exception: nil, message: nil, course: nil)
    error = {}

    error[:message] = message || exception.try(:message)
    error[:exception] = {
      class: exception.class.name,
      message: exception.message,
      first_backtrace_line: exception.backtrace.try(:first)
    } if exception.present?
    error[:course] = course.id if course.present?

    @errors.push(error)
  end

  def notify_errors
    return if @errors.empty?

    Rails.logger.warn { "#{class.name} errors: " + @errors.inspect }

    if @allow_error_email && is_real_production?
      DevMailer.inspect_object(
        object: @errors,
        subject: "#{class.name} errors",
        to: Rails.application.secrets.salesforce['mail_recipients']
      ).deliver_later
    end
  end

  def is_real_production?
    Rails.application.secrets.environment_name == "prodtutor"
  end

end
