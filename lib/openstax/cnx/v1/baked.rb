module OpenStax::Cnx::V1::Baked
  def self.parse_title(title)
    text_node = Nokogiri::HTML.fragment(title).at_css('.os-text')
    if text_node.present?
      { text: text_node.text, book_location: part.css('.os-number').text.split('.') }
    else
      { text: title, book_location: [] }
    end
  end
end
