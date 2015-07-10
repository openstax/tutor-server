require 'hashie/mash'
require 'yaml'
require 'erb'

class ContentConfiguration
  # Yaml files will be located inside this directory
  CONFIG_DIR = File.dirname(__FILE__)

  # Methods in this class are available inside ERB blocks in the YAML file
  class YamlERB

    attr_reader :noon_today

    def initialize
      @noon_today = Time.now.noon
    end

    def get_binding
      binding
    end

    def school_day_on_or_before(time)
      while time.sunday? || time.saturday?
        time = time.yesterday
      end
      time
    end

    def today
      @noon_today
    end

    def standard_due_at(time)
      time.midnight + 7.hours
    end

    def due_today
      standard_due_at(school_day_on_or_before(noon_today))
    end

    def due_one_day_ago
      standard_due_at(school_day_on_or_before(due_today))
    end

    def due_two_days_ago
      standard_due_at(school_day_on_or_before(due_one_day_ago - 2.days))
    end

    def due_three_days_ago
      standard_due_at(school_day_on_or_before(due_two_days_ago - 3.days))
    end

  end

  class ConfigFileParser
    def initialize(file_path)
      @content = File.read(file_path)
      @helpers = YamlERB.new
      @file_path = file_path
    end

    def perform
      template = ERB.new(@content)
      template.filename = @file_path
      YAML.load template.result(@helpers.get_binding)
    end

    def self.perform(file_path)
      new(file_path).perform
    end
  end

  extend Forwardable

  def self.[](name)
    files = if :all == name
              Dir[File.join(CONFIG_DIR, '*.yml')]
            else
              [ File.join(CONFIG_DIR, "#{name}.yml") ]
            end
    files
      .reject{|path| File.basename(path) == "people.yml" }
      .map{|file| self.new(file) }
  end

  def_delegators :@configuration, :course_name, :assignments, :teacher, :period_names

  def initialize(config_file)
    @configuration = Hashie::Mash.load(config_file, parser: ConfigFileParser)
    validate_config
  end

  def cnx_book
    version = if @configuration.cnx_book_version.blank? || @configuration.cnx_book_version == 'latest'
                ''
              else
                "@#{@configuration.cnx_book_version}"
              end
    "#{@configuration.cnx_book_id}#{version}"
  end

  def course
    @course ||= CourseProfile::Models::Profile.where(name: @configuration.course_name).first!.course
  end

  private

  def validate_config
    # loop through each assignment and verify that the same student isn't in multiple periods
    @configuration.assignments.each do | assignment |
      assignment.periods.each do | period |
        initials = period.students.keys
        # it's tempting to attempt to find if the same student was listed twice in a period
        # But we can't do that since students is a hash,
        # and a duplicate student would just be a duplicate key and latter overwrites previous

        @configuration.assignments.each do | testing_assignment |
          testing_assignment.periods.each do | testing_period |
            next if testing_period['index'] == period['index']
            common_students = initials & testing_period.students.keys
            unless common_students.blank?
              raise "#{@configuration.course_name} has student(s) #{common_students.join(',')} in both '#{@configuration.period_names[period['index']]}' and '#{@configuration.period_names[testing_period['index']]}'"
            end

          end
        end
      end
    end
  end
end
