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

    def standard_opens_at(time)
      time.midnight + 1.minute
    end

    def standard_due_at(time)
      time.midnight + 7.hours
    end

    def open_today
      standard_opens_at(school_day_on_or_before(today))
    end

    def open_one_day_ago
      standard_opens_at(school_day_on_or_before(today - 1.day))
    end

    def open_two_days_ago
      standard_opens_at(school_day_on_or_before(today - 2.days))
    end

    def open_three_days_ago
      standard_opens_at(school_day_on_or_before(today - 3.days))
    end

    def due_today
      standard_due_at(today)
    end

    def due_one_day_ago
      standard_due_at(school_day_on_or_before(today - 1.day))
    end

    def due_two_days_ago
      standard_due_at(school_day_on_or_before(today - 2.days))
    end

    def due_three_days_ago
      standard_due_at(school_day_on_or_before(today - 3.days))
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
              Dir[File.join(self.config_directory, '*.yml')]
            else
              [ File.join(self.config_directory, "#{name}.yml") ]
            end
    files
      .reject{|path| File.basename(path) == "people.yml" }
      .map{|file| self.new(file) }
  end

  def_delegators :@configuration, :course_name, :assignments, :teacher, :periods

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

  def self.config_directory
    Thread.current[:config_directory] || ENV['CONFIG'] || CONFIG_DIR
  end

  def self.with_config_directory( directory )
    prev_config, Thread.current[:config_directory] = self.config_directory, directory
    yield self
  ensure
    Thread.current[:config_directory] = prev_config
  end

  def get_period(id)
    @configuration.periods.detect{|period| period['id'] == id}
  end

  private

  def validate_config
    # loop through each assignment and verify that the students match the roster for the period
    @configuration.assignments.each do | assignment |
      assignment.periods.each_with_index do | period, index |
        period_config = get_period(period.id)
        if period_config.nil?
          raise "Unable to find period # #{index} id #{period.id} for assignment #{assignment.title}"
        end
        if period_config.students.sort != period.students.keys.sort
          raise "Students assignments for #{@configuration.course_name} period #{period_config.name} do not match for assignment #{assignment.title}"
        end
      end
    end
  end
end
