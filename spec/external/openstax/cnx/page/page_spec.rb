require 'spec_helper'
require 'open-uri'

def fetch_cnx_item(id)
  url_base ='http://archive.cnx.org/contents/'
  url      = "#{url_base}#{id}"
  hash     = JSON.parse open(url, 'ACCEPT' => 'text/json').read
end

module OpenStax
  module Cnx

    class ReadingFragment
    end

    class ExerciseFragment
    end

    class VideoFragment
    end

    class SimulationFragment
    end

    class Page
      # def initialize(title:, fragments:, los:)
      def initialize(id:, title:, content:)
        @id      = id
        @title   = title
        @content = content
      end

      def to_s(indent: 0)
        "#{' '*indent}PAGE #{@title} // #{@id}\n"
      end

      def self.from_contents_hash(hash)
        page_hash = fetch_cnx_item(hash['id'])
        content = page_hash.fetch('content') { raise "ill-formed Page (id=#{id})" }
        Page.new(id: hash['id'], title: hash['title'], content: content)
      end
    end

    class BookPart
      def initialize(title:, parts:)
        @title = title
        @parts = parts
      end

      def to_s(indent: 0)
        s = "#{' '*indent}PART #{@title}\n"
        s << @parts.collect{|part| part.to_s(indent: indent+2)}.join('')
      end

      def self.from_contents_array(title:, array:)
        # puts "BookPart.from_contents_array(#{title})"
        parts = array.collect do |hash|
          if hash['id'] == 'subcol'
            BookPart.from_contents_array(title: hash['title'], array: hash['contents'])
          else
            Page.from_contents_hash(hash)
          end
        end

        BookPart.new(title: title, parts: parts)
      end
    end

    class Book
      def initialize(root_book_part:)
        @root_book_part = root_book_part
      end

      def to_s(indent: 0)
        @root_book_part.to_s(indent: indent)
      end

      def self.fetch(id)
        # puts "Book.fetch(#{id}) called"
        hash     = fetch_cnx_item(id)
        title    = hash.fetch('title')    {|key| raise "Book id=#{id} is missing #{key}"}
        tree     = hash.fetch('tree')     {|key| raise "Book id=#{id} is missing #{key}"}
        id       = tree.fetch('id')       {|key| raise "Book id=#{id} is missing tree #{key}"}
        contents = tree.fetch('contents') {|key| raise "Book id=#{id} is missing tree #{key}"}

        book_part = BookPart.from_contents_array(title: title, array: contents)
        Book.new(root_book_part: book_part)
      end
    end

  end
end

describe OpenStax::Cnx::Page do
  context "some context" do
    let!(:bio_book_id)          { '185cbf87-c72e-48f5-b51e-f14f21b5eabd@9.80' }
    let!(:concepts_bio_book_id) { 'b3c1e1d2-839c-42b0-a314-e119a8aafbdd@8.53' }
    let!(:test_book_id)         { '7db9aa72-f815-4c3b-9cb6-d50cf5318b58@1.4' }
    let!(:statistics_book_id)   { '30189442-6998-4686-ac05-ed152b91b9de@17.42' }
    let!(:us_history_book_id)   { 'a7ba2fb8-8925-4987-b182-5f4429d48daa@3.7' }
    let!(:macro_econ_book_id)   { '4061c832-098e-4b3c-a1d9-7eb593a2cb31@10.58' }
    # let!(:_book_id)       { '' }
    # let!(:_book_id)       { '' }
    let!(:book_ids) { [test_book_id, bio_book_id, concepts_bio_book_id,
                       statistics_book_id, us_history_book_id, macro_econ_book_id]}

    it "wraps the json" do
      [test_book_id].each do |book_id|
        puts "="*40
        puts OpenStax::Cnx::Book.fetch(book_id).to_s
      end
    end
  end
end
