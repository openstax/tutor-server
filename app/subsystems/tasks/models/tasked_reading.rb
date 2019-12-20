class Tasks::Models::TaskedReading < IndestructibleRecord
  acts_as_tasked

  json_serialize :book_location, Integer, array: true
  json_serialize :baked_book_location, Integer, array: true

  validates :url, presence: true
  validates :content, presence: true

  def has_content?
    true
  end

  def has_learning_objectives?
    content_dom.css('.learning-objectives').present?
  end

  def content_preview
    document_title.presence || data_title.presence || class_title.presence || task_step.page.title
  end

  private

  def class_title
    content_dom.xpath("//*[contains(@class, 'os-title')]").first&.inner_html&.strip
  end

  def document_title
    content_dom.xpath("//*[@data-type='document-title']").first&.inner_html&.strip
  end

  def data_title
    content_dom.xpath("//*[@data-type='title']").first&.inner_html&.strip
  end

  def content_dom
    @content_dom ||= Nokogiri::HTML(content)
  end
end
