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

  def_delegators :@configuration, :course_name, :assignments, :teacher, :periods

  def initialize(config_file)
    @configuration = Hashie::Mash.load(config_file, parser: ConfigFileParser)
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

  def people
    @people ||= Hashie::Mash.load(File.dirname(__FILE__)+"/people.yml")
  end

end
