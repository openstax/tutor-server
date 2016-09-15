require 'hashie/mash'
require 'yaml'
require 'erb'
require_relative 'content_configuration_yaml_methods'

# Reads in a YAML file containg configuration for a course and its students
class Demo::ContentConfiguration
  # Yaml files will be located inside this directory
  DEFAULT_CONFIG_DIR = File.join(File.dirname(__FILE__), 'config')

  # File paths including any of these words are always excluded
  EXCLUDED_CONFIGURATIONS = ['base', 'people']

  # File paths including any of these words are excluded when running the "all" config
  EXPLICIT_CONFIGURATIONS = ['large', 'ludicrous', 'mini', 'real', 'small', 'test']

  class ConfigFileParser
    def initialize(file_path)
      @content = File.read(file_path)
      @helpers = Demo::ContentConfigurationYamlMethods.new
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
    # The directory for the config files can be either set using either
    # config_directory block (which sets it's value using RequestStore.store),
    # the CONFIG environmental variable or the default
    config_directory = RequestStore.store[:config_directory] ||
                       ENV['CONFIG'] || DEFAULT_CONFIG_DIR

    all_files = Dir[File.join(config_directory, '**/*.yml')]

    name_string = name.to_s

    if name_string == 'all'
      exclusions = EXCLUDED_CONFIGURATIONS + EXPLICIT_CONFIGURATIONS
      inclusion = ''
    else
      exclusions = EXCLUDED_CONFIGURATIONS
      inclusion = name_string
    end

    files = all_files.select do |path|
      rpath = path.sub(config_directory, '')

      rpath.include?(inclusion) && exclusions.none?{ |exclusion| rpath.include? exclusion }
    end

    files.map{|file| self.new(file) }
  end

  def_delegators :@configuration, :course_name, :teachers,
                 :appearance_code, :salesforce_book_name,
                 :is_concept_coach, :is_college, :reading_processing_instructions

  def initialize(config_file)
    @configuration = Hashie::Mash.load(config_file, parser: ConfigFileParser)
    validate_config
  end

  def archive_url_base
    @configuration.archive_url_base ||
      Rails.application.secrets.openstax['cnx']['archive_url']
  end

  def webview_url_base
    @configuration.webview_url_base
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

  def cnx_book(book_version=:defined)
    version = if book_version.to_sym != :defined
                book_version.to_sym == :latest ? '' : "@#{book_version}"
              elsif @configuration.cnx_book_version.blank? || @configuration.cnx_book_version == 'latest'
                ''
              else
                "@#{@configuration.cnx_book_version}"
              end
    "#{@configuration.cnx_book_id}#{version}"
  end

  def course
    @course ||= CourseProfile::Models::Profile.where(name: course_name)
                                              .order{created_at.desc}.first!.course
  end

  def self.with_config_directory( directory )
    prev_config = RequestStore.store[:config_directory]
    RequestStore.store[:config_directory] = directory
    yield self
  ensure
    RequestStore.store[:config_directory] = prev_config
  end

  def get_period(id)
    @configuration.periods.detect{|period| period['id'] == id}
  end

  private

  def validate_config
    # make sure the titles for assignments are unique
    titles = assignments.map(&:title)
    duplicate = titles.detect {|e| titles.rindex(e) != titles.index(e) }
    raise "Assignment #{duplicate} for #{course_name} is listed more than once" if duplicate
    # loop through each assignment and verify that the students match the roster for the period
    assignments.each do | assignment |
      assignment.periods.each_with_index do | period, index |
        period_config = get_period(period.id)
        if period_config.nil?
          raise "Unable to find period # #{index} id #{period.id} for assignment #{assignment.title}"
        end
        if period_config.students.sort != period.students.keys.sort
          raise "Students assignments for #{course_name} period #{period_config.name} do not match for assignment #{assignment.title}"
        end
      end
    end
  end
end
