class Content::GetPage

  lev_routine express_output: :page

  protected

  def exec(id:)
    page = Content::Models::Page.find(id)
    outputs[:page] = OpenStax::Cnx::V1::Page.new(id: id,
                                                 content: page.content,
                                                 hash: {},
                                                 path: page.path,
                                                 title: page.title,
                                                 url: page.url)
  end

end
