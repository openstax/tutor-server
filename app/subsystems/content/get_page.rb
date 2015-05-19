class Content::GetPage

  lev_routine express_output: :page

  protected

  def exec(id:)
    page = Content::Models::Page.includes(:book_part).find(id)
    outputs[:page] = Page.new(page)
  end

end
