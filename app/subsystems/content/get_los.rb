class Content::GetLos

  lev_routine express_output: :los

  protected

  def exec(options = {})
    page_ids = [options[:page_ids]].flatten.compact
    book_part_ids = [options[:book_part_ids]].flatten.compact
    book_part_ids.each do |book_part_id|
      book_part = Content::Models::BookPart.find(book_part_id)
      page_ids += Content::VisitBookPart[book_part: book_part,
                                         visitor_names: 'page_data']
                    .collect{|info| info[:id]}
    end

    outputs[:los] = Content::Models::Tag.lo
                                        .joins(:page_tags)
                                        .where(page_tags: {
                                          content_page_id: page_ids
                                        }).pluck(:value)
  end

end
