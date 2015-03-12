class OpenStax::Cnx::V1::BookPart
  def initialize(title:, parts:)
    @title = title
    @parts = parts
  end

  def to_s(indent: 0)
    s = "#{' '*indent}PART #{@title}\n"
    s << @parts.collect{|part| part.to_s(indent: indent+2)}.join('')
  end

  def self.from_contents_array(title:, array:)
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
