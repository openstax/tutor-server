require 'open-uri'

module OpenStax::Cnx::V1

  ARCHIVE_URL_BASE ='http://archive.cnx.org/contents/'
  SSL_ARCHIVE_URL_BASE ='https://archive.cnx.org/contents/'

  def self.url_for(id, options={})
    options[:secure] ||= false
    URI::join((options[:secure] ? SSL_ARCHIVE_URL_BASE : ARCHIVE_URL_BASE), id).to_s
  end

  def self.fetch(id)
    JSON.parse open(url_for(id), 'ACCEPT' => 'text/json').read
  end

  def self.book(options = {})
    OpenStax::Cnx::V1::Book.new(options)
  end

end
