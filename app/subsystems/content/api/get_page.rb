class Content::GetPage

  lev_routine

  protected

  def exec(page_id:)
    page = Content::Page.find(page_id)
    outputs[:page] = {
      url: page.url,
      content: page.content
    }
  end

end