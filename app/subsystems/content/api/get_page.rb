class Content::Api::GetPage

  lev_routine

  protected

  def exec(id:)
    page = Content::Page.find(id)
    page_hash = { id: '', url: page.url, hash: {},
                  title: page.title, content: page.content }
    outputs[:page] = OpenStax::Cnx::V1::Page.new(page_hash)
  end

end
