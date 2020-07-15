class OpenStax::Cnx::V1::Title
  attr_reader :book_location, :text

  def initialize(title)
    return nil if title.nil?

    part = Nokogiri::HTML.fragment(title)
    number_node = part.css('.os-number')
    if number_node.present?
      @book_location = number_node.text.gsub(/[^\.\d]/, '').split('.').map do |number|
        Integer(number) rescue nil
      end.compact
    end
    @book_location = [] if @book_location.nil?
    @text = title
  end
end
