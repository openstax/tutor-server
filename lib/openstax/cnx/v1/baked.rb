module OpenStax::Cnx::V1::Baked
  def self.parse_title(title)
    part = Nokogiri::HTML.parse(title)
    text_node = part.css('.os-text')
    if text_node.present?
      { text: text_node.text,
        book_location: part.css('.os-number').text }
    else
      { text: title }
    end
  end
end
