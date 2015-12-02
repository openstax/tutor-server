require 'addressable/uri'
require 'open-uri'

require_relative './v1/fragment_splitter'
require_relative './v1/fragment/acts_as_fragment'
require_relative './v1/fragment/embedded'
require_relative './v1/fragment/exercise'
require_relative './v1/fragment/exercise_choice'
require_relative './v1/fragment/feature'
require_relative './v1/fragment/interactive'
require_relative './v1/fragment/text'
require_relative './v1/fragment/video'
require_relative './v1/book'
require_relative './v1/book_part'
require_relative './v1/page'
require_relative './v1/book_visitor'
require_relative './v1/book_to_string_visitor'

module OpenStax::Cnx::V1

  # Sets the archive URL base.  'url' is nominally the non-SSL URL,
  # tho may be SSL. An explicit SSL URL can be passed in `ssl`, or
  # by default the SSL URL will be guessed from the URL.
  def self.set_archive_url_base(url: nil, ssl: nil)
    uri = Addressable::URI.parse(url || ssl)
    uri.scheme = 'http'
    @archive_url_base = uri.to_s
    uri = Addressable::URI.parse(ssl) unless ssl.nil?
    uri.scheme = 'https'
    @ssl_archive_url_base = uri.to_s
  end

  def self.archive_url_base(ssl: false)
    ssl ? @ssl_archive_url_base : @archive_url_base
  end

  def self.with_archive_url(url:, ssl: nil)
    old_url = archive_url_base
    old_ssl_url = archive_url_base(ssl: true)

    begin
      set_archive_url_base(url: url, ssl: ssl)
      yield
    ensure
      set_archive_url_base(url: old_url, ssl: old_ssl_url)
    end
  end

  def self.url_for(id, options={})
    options[:secure] = true if options[:secure].nil?
    Addressable::URI.join(archive_url_base(ssl: options[:secure]), id).to_s
  end

  def self.fetch(id)
    url = url_for(id)

    begin
      Rails.logger.debug { "Fetching #{url}" }
      JSON.parse open(url, 'ACCEPT' => 'text/json').read
    rescue OpenURI::HTTPError => e
      raise OpenStax::HTTPError, "#{e.message} for URL #{url}"
    end
  end

  def self.book(options = {})
    OpenStax::Cnx::V1::Book.new(options)
  end

end
