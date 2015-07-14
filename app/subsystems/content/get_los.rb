class Content::GetLos

  lev_routine express_output: :all

  protected

  def exec(options = {})
    page_ids = [options[:page_ids]].flatten.compact
    book_part_ids = [options[:book_part_ids]].flatten.compact

    page_ids += Content::Models::Page.where(content_book_part_id: book_part_ids)
                                     .pluck(:id)

    outputs[:los] = Content::Models::Tag.lo
                                        .joins(:page_tags)
                                        .where(page_tags: {
                                          content_page_id: page_ids
                                        }).pluck(:value)

    outputs[:aplos] = Content::Models::Tag.aplo
                                          .joins(:page_tags)
                                          .where(page_tags: {
                                            content_page_id: page_ids
                                          }).pluck(:value)

    outputs[:all] = outputs[:los] + outputs[:aplos]
  end

end
