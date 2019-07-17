# Reads in a YAML file containg configuration for a course and its students
class Demo::Config::Course < Demo::Config::Content
  def_delegators :@configuration,
                 :id, :id=, :course_name, :salesforce_book_name, :is_college, :teachers

  def self.config_dir
    File.join(Demo::Base::CONFIG_BASE_DIR, 'courses')
  end

  def assignments
    @configuration.assignments || []
  end

  def auto_assign
    @configuration.auto_assign || []
  end

  def periods
    @configuration.periods || []
  end

  def get_period(id)
    @configuration.periods.find { |period| period['id'] == id }
  end

  protected

  def validate_config
    # Make sure the titles for assignments are unique
    titles = assignments.map(&:title)
    duplicate = titles.find { |e| titles.rindex(e) != titles.index(e) }
    raise "Assignment #{duplicate} for #{course_name} is listed more than once" if duplicate

    # Loop through each assignment and verify that the students match the roster for the period
    assignments.each do | assignment |
      assignment.periods.each_with_index do | period, index |
        period_config = get_period(period.id)
        if period_config.nil?
          raise "Unable to find period # #{index} id #{
                period.id} for assignment #{assignment.title}"
        end

        if period.students.nil? || period_config.students.sort != period.students.keys.sort
          raise "Students assignments for #{course_name} period #{period_config.name
                } do not match for assignment #{assignment.title}"
        end
      end
    end
  end
end
