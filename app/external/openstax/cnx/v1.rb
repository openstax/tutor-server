require 'open-uri'

module OpenStax::Cnx::V1

  # Sets the archive URL base.  'url' is nominally the non-SSL URL,
  # tho may be SSL.  An explicit SSL URL can be passed in `ssl`, or
  # by default the SSL URL will be guessed from the URL.
  def self.set_archive_url_base(url:, ssl: :automatic)
    @archive_url_base = url
    @ssl_archive_url_base = (ssl == :automatic) ?
                            url.gsub('http://','https://') :
                            ssl
  end

  def self.archive_url_base(ssl: false)
    set_archive_url_base(url: 'http://archive.cnx.org/contents/') if @archive_url_base.nil?
    ssl ? @ssl_archive_url_base : @archive_url_base
  end

  def self.with_archive_url(url:)
    old_url = archive_url_base
    old_ssl_url = archive_url_base(ssl: true)

    set_archive_url_base(url: url)
    result = yield
    set_archive_url_base(url: old_url, ssl: old_ssl_url)
    result
  end

  def self.url_for(id, options={})
    options[:secure] ||= false
    URI::join((options[:secure] ? archive_url_base(ssl: true) : archive_url_base), id).to_s
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
