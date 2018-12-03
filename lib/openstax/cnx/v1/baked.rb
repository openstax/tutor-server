module OpenStax::Cnx::V1::Baked
  def self.parse_title(title)
    return nil if title.nil?

    part = Nokogiri::HTML.fragment(title)
    text_node = part.css('.os-text')
    if text_node.present?
      { text: text_node.text, book_location: part.css('.os-number').text.split('.') }
    else
      { text: title, book_location: [] }
    end
  end
end
