require 'addressable/uri'
require 'open-uri'

require_relative './v1/custom_css'

require_relative './v1/fragment'
require_relative './v1/fragment/embedded'
require_relative './v1/fragment/video'
require_relative './v1/fragment/interactive'
require_relative './v1/fragment/reading'
require_relative './v1/fragment/exercise'
require_relative './v1/fragment/optional_exercise'
require_relative './v1/fragment_splitter'

require_relative './v1/book'
require_relative './v1/book_part'
require_relative './v1/page'

module OpenStax::Cnx::V1

  mattr_reader :archive_url_base

  # Sets the archive URL base. Forces https.
  def self.archive_url_base=(url)
    uri = Addressable::URI.parse(url)
    uri.scheme = 'https'
    @@archive_url_base = uri.to_s
  end

  def self.with_archive_url(url)
    old_url = archive_url_base

    begin
      self.archive_url_base = url
      yield
    ensure
      self.archive_url_base = old_url
    end
  end

  def self.webview_url_base
    archive_url_base.sub(/archive[\.-]?/, '')
  end

  # Archive url for the given path
  # Forces /contents/ to be prepended to the path, unless the path begins with /
  def self.archive_url_for(path)
    Addressable::URI.join(archive_url_base, '/contents/', path).to_s
  end

  # Webview url for the given path
  # Forces /contents/ to be prepended to the path, unless the path begins with /
  def self.webview_url_for(path)
    Addressable::URI.join(webview_url_base, '/contents/', path).to_s
  end

  def self.fetch(id)
    url = archive_url_for(id)

    begin
      Rails.logger.debug { "Fetching #{url}" }
      JSON.parse open(url, 'ACCEPT' => 'text/json').read
    rescue OpenURI::HTTPError => exception
      raise OpenStax::HTTPError, "#{exception.message} for URL #{url}"
    end
  end

  def self.book(options = {})
    OpenStax::Cnx::V1::Book.new(options)
  end

end
