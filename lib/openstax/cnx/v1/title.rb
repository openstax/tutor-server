class OpenStax::Cnx::V1::Title
  attr_reader :book_location, :text

  def initialize(title)
    return nil if title.nil?

    part = Nokogiri::HTML.fragment(title)
    text_node = part.css('.os-text')
    if text_node.present? && (number = part.at_css('.os-number'))
      number.css('.os-part-text').each(&:remove)      
      @book_location = number.text.split('.').map do |number|
        Integer(number) rescue nil
      end.compact
      @text = text_node.inner_html
    else
      @book_location = []
      @text = part.text.strip
    end
  end
end
