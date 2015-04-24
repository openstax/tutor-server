class Content::GetPageFromLo

  lev_routine express_output: :page

  uses_routine Content::Routines::SearchPages, as: :search

  protected

  def exec(lo:)
    page = run(:search, tag: lo).outputs.items.first
    outputs[:page] = OpenStax::Cnx::V1::Page.new(
      id: id, content: page.content, hash: {},
      path: page.path, title: page.title, url: page.url,
      book_part_title: page.book_part.try(:title)
    )
  end

end
