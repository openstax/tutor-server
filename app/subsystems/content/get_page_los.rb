class Content::GetPageLos

  lev_routine express_output: :los

  protected

  def exec(page_ids:)
    outputs[:los] = Content::Models::Tag.joins(:page_tags).where(page_tags: {
      content_page_id: page_ids
    }).pluck(:name)
  end

end
