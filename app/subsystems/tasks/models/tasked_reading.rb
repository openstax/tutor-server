class Tasks::Models::TaskedReading < IndestructibleRecord
  acts_as_tasked

  json_serialize :book_location, Integer, array: true
  json_serialize :baked_book_location, Integer, array: true

  validates :url, presence: true
  validates :content, presence: true

  def has_content?
    true
  end

  def content_preview
    text = document_title.presence || data_title.presence || class_title.presence
    text || "Unknown"
  end

  private

  def class_title
    text = content_dom.xpath("//*[contains(@class, 'os-title')]").first.try(:text).try(:strip)
    text.try(:split, /\n+/).try(:first)
  end

  def document_title
    content_dom.xpath("//*[contains(@data-type, 'document-title')]").first.try(:text).try(:strip)
  end

  def data_title
    content_dom.xpath("//*[contains(@data-type, 'title')]").first.try(:text).try(:strip)
  end

  def content_dom
    @content_dom ||= Nokogiri::HTML(content)
  end
end
