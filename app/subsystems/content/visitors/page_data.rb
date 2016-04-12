class Content::Visitors::PageData < Content::Visitors::Book

  def initialize
    @page_data = []
  end

  def visit_page(page)
    @page_data << {
      id: page.id,
      tags: get_page_tags(page),
      los: get_page_los(page),
      aplos: get_page_aplos(page),
      title: page.title,
      chapter_section: page.chapter_section,
      url: page.url,
      version: get_page_version(page)
    }
  end

  def output
    @page_data
  end

  private
  def get_page_los(page)
    tags = get_page_tags(page)
    tags.select { |tag| tag[:type] == 'lo' }.map { |tag| tag[:value] }
  end

  def get_page_aplos(page)
    tags = get_page_tags(page)
    tags.select { |tag| tag[:type] == 'aplo' }.map { |tag| tag[:value] }
  end

  def get_page_tags(page)
    @tags ||= {}
    @tags[page.id] ||= page.page_tags.includes(:tag).map do |page_tag|
      { type: page_tag.tag.tag_type, value: page_tag.tag.value }
    end
  end

  def get_page_version(page)
    page.url.gsub(%r{.*/}, '')
  end
end
