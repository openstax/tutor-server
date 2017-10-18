require_relative 'content'

# Reads in a YAML file containg configuration for a CNX book
class Demo::Config::Book < Demo::Config::Content
  # Yaml files will be located inside this directory
  DEFAULT_CONFIG_DIR = File.join(Rails.root, 'config/demo/books')

  extend Forwardable

  def_delegators :@configuration, :salesforce_book_name, :appearance_code, :default_course_name,
                                  :is_tutor, :is_concept_coach, :reading_processing_instructions

  def archive_url_base
    @configuration.archive_url_base || Rails.application.secrets.openstax['cnx']['archive_url']
  end

  def webview_url_base
    @configuration.webview_url_base
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
end
