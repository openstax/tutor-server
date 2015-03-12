puts "======= #{__FILE__}:#{__LINE__} ======="

require_relative 'page/v1/page'
require_relative 'book_part/v1/book_part'
require_relative 'book/v1/book'

require 'open-uri'

module OpenStax::Cnx::V1
  def self.fetch(id)
    url_base ='http://archive.cnx.org/contents/'
    url      = "#{url_base}#{id}"
    hash     = JSON.parse open(url, 'ACCEPT' => 'text/json').read
  end
end
