class Content::Models::PageDataVisitor < Content::Models::BookVisitor

  def initialize
    @page_data = []
  end

  def visit_page(page)
    page_id      = page.id
    page_tags    = page.page_tags.collect{|page_tag| {type: page_tag.tag.tag_type, name: page_tag.tag.name}}
    page_los     = page_tags.select{|tag| tag[:type] == 'lo'}.collect{|tag| tag[:name]}
    page_title   = page.title
    page_url     = page.url
    page_version = get_version(page_url)

    page_info = {
      id:      page.id,
      tags:    page_tags,
      los:     page_los,
      title:   page_title,
      url:     page_url,
      version: page_version
    }

    @page_data << page_info
  end

  def output
    @page_data
  end

  protected

  def get_version(url)
    url.gsub(%r{.*/}, '')
  end
end
