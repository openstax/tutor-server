require_relative 'content'

# Reads in a YAML file containg configuration for a CNX book
class Demo::Config::Book < Demo::Config::Content
  def_delegators :@configuration, :salesforce_book_name, :appearance_code, :default_course_name,
                                  :is_tutor, :is_concept_coach, :reading_processing_instructions

  def self.config_dir
    File.join(Demo::Base::CONFIG_BASE_DIR, 'books')
  end

  def archive_url_base
    @configuration.archive_url_base || Rails.application.secrets.openstax['cnx']['archive_url']
  end

  def webview_url_base
    @configuration.webview_url_base
  end

  def book_id(book_version=:defined)
    version = if book_version.to_sym != :defined
      book_version.to_sym == :latest ? '' : "@#{book_version}"
    elsif @configuration.cnx_book_version.blank? || @configuration.cnx_book_version == 'latest'
      ''
    else
      "@#{@configuration.cnx_book_version}"
    end

    "#{@configuration.cnx_book_id}#{version}"
  end

  def archive_url
    "#{archive_url_base}#{book_id}"
  end

  def webview_url
    "#{webview_url_base || archive_url_base.sub(/archive\./, '')}#{book_id}"
  end

  def pdf_url
    "#{archive_url_base.sub(%r{contents/$}, 'exports/')}#{book_id}.pdf"
  end
end
