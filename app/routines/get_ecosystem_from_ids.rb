class GetEcosystemFromIds
  lev_routine outputs: { ecosystem: :_self }

  protected

  def exec(book_ids: nil, chapter_ids: nil, page_ids: nil, exercise_ids: nil)
    book_ecosystem = nil
    unless book_ids.nil?
      book_ecosystem = ::Content::Ecosystem.find_by_book_ids(*book_ids)
      fatal_error(code: :no_ecosystem,
                  message: "No ecosystem found for book ids: #{book_ids}") if book_ecosystem.nil?
    end

    chapter_ecosystem = nil
    unless chapter_ids.nil?
      chapter_ecosystem = ::Content::Ecosystem.find_by_chapter_ids(*chapter_ids)
      fatal_error(code: :no_ecosystem,
                  message: "No ecosystem found for chapter ids: #{chapter_ids}") \
        if chapter_ecosystem.nil?
    end

    page_ecosystem = nil
    unless page_ids.nil?
      page_ecosystem = ::Content::Ecosystem.find_by_page_ids(*page_ids)
      fatal_error(code: :no_ecosystem,
                  message: "No ecosystem found for page ids: #{page_ids}") if page_ecosystem.nil?
    end

    exercise_ecosystem = nil
    unless exercise_ids.nil?
      exercise_ecosystem = ::Content::Ecosystem.find_by_exercise_ids(*exercise_ids)
      fatal_error(code: :no_ecosystem,
                  message: "No ecosystem found for exercise ids: #{exercise_ids}") \
        if exercise_ecosystem.nil?
    end

    ecosystems = [book_ecosystem, chapter_ecosystem, page_ecosystem, exercise_ecosystem].compact.uniq
    fatal_error(code: :argument_error,
                message: 'You must specify at least one of :book_ids, :chapter_ids, ' +
                         ':page_ids or :exercise_ids') if ecosystems.blank?

    fatal_error(code: :multiple_ecosystems,
                message: 'More than one ecosystem found for the specified ids') \
      if ecosystems.size > 1

    set(ecosystem: ecosystems.first)
  end
end
