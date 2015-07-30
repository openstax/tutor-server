require 'addressable/uri'
require 'open-uri'

module OpenStax::Cnx::V1

  # Sets the archive URL base.  'url' is nominally the non-SSL URL,
  # tho may be SSL. An explicit SSL URL can be passed in `ssl`, or
  # by default the SSL URL will be guessed from the URL.
  def self.set_archive_url_base(url:, ssl: nil)
    uri = Addressable::URI.parse(url)
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
    Rails.logger.debug { "Fetching #{url}" }
    JSON.parse open(url_for(id), 'ACCEPT' => 'text/json').read
  end

  def self.book(options = {})
    OpenStax::Cnx::V1::Book.new(options)
  end

end
