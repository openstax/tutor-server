class Content::Api::GetPage

  lev_routine

  protected

  def exec(id:)
    page = Content::Page.find(id)
    outputs[:page] = {
      url: page.url,
      content: page.content
    }
  end

end
