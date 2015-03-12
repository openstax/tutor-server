puts "======= #{__FILE__}:#{__LINE__} ======="

module OpenStax::Cnx::V1
  class Book
    def initialize(id:, root_book_part:)
      @id             = id
      @root_book_part = root_book_part
    end

    def to_s(indent: 0)
      s = "#{@id}\n"
      s << @root_book_part.to_s(indent: indent)
    end

    def self.fetch(id)
      # puts "Book.fetch(#{id}) called"
      hash     = OpenStax::Cnx::V1.fetch(id)
      title    = hash.fetch('title')    {|key| raise "Book id=#{id} is missing #{key}"}
      tree     = hash.fetch('tree')     {|key| raise "Book id=#{id} is missing #{key}"}
      id       = tree.fetch('id')       {|key| raise "Book id=#{id} is missing tree #{key}"}
      contents = tree.fetch('contents') {|key| raise "Book id=#{id} is missing tree #{key}"}

      book_part = BookPart.from_contents_array(title: title, array: contents)
      Book.new(id: id, root_book_part: book_part)
    end
  end
end
