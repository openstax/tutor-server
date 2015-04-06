class Content::Models::PageDataVisitor < Content::Models::BookVisitor

  def initialize
    @page_data = []
  end

  def visit_page(page)
    @page_data << {
      id: page.id,
      tags: get_page_tags(page),
      los: get_page_los(page),
      title: page.title,
      path: page.path,
      url: page.url,
      version: get_page_version(page)
    }
  end

  def output
    @page_data
  end

  private
  def get_page_path(page)
    page.page_tags.collect do |page_tag|
      { type: page_tag.tag.tag_type, name: page_tag.tag.name }
    end
  end

  def get_page_los(page)
    tags = get_page_tags(page)
    tags.select { |tag| tag[:type] == 'lo' }.collect { |tag| tag[:name] }
  end

  def get_page_tags(page)
    page.page_tags.collect do |page_tag|
      { type: page_tag.tag.tag_type, name: page_tag.tag.name }
    end
  end

  def get_page_version(page)
    page.url.gsub(%r{.*/}, '')
  end
end
