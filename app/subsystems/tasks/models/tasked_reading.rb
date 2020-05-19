class Tasks::Models::TaskedReading < IndestructibleRecord
  acts_as_tasked

  json_serialize :book_location, Integer, array: true

  delegate :fragment_index, to: :task_step

  validates :url, :fragment_index, presence: true

  def content
    cont = super
    return cont unless cont.nil?

    return if fragment_index.nil?

    fragments = task_step&.page&.fragments
    return if fragments.nil?

    fragments[fragment_index]&.to_html
  end

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
    content_dom.css('.os-title').first&.inner_html&.strip
  end

  def document_title
    content_dom.css('[data-type="document-title"]').first&.inner_html&.strip
  end

  def data_title
    content_dom.css('[data-type="title"]').first&.inner_html&.strip
  end

  def content_dom
    @content_dom ||= Nokogiri::HTML.fragment(content)
  end

  def can_be_auto_graded?
    true
  end
end
