class Content::VisitBookPart

  lev_routine

  protected

  def exec(book_part:, visitor_names:)
    # handle string or symbol names, array or single entry
    visitor_names = [visitor_names].flatten.collect(&:to_sym)

    uncached_visitor_names = process_cached_visitors(book_part, visitor_names)
    process_uncached_visitors(book_part, uncached_visitor_names)

    enable_express_output_if_only_one_visitor(visitor_names)
  end

  private

  VISITOR_INFO = {
    toc: {
      visitor_class: Content::Models::TocVisitor,
      cached_attribute: :toc_cache
    },
    exercises: {
      visitor_class: Content::Models::ExerciseVisitor
    },
    page_data: {
      visitor_class: Content::Models::PageDataVisitor,
      cached_attribute: :page_data_cache
    }
  }

  def process_cached_visitors(book_part, visitor_names)
    uncached_visitor_names = []

    visitor_names.each do |visitor_name|
      cached_value = get_cached_value(book_part, visitor_name)

      if cached_value
        # Put the cached value in the output
        outputs[visitor_name] = cached_value
      else
        # Take a note that we still need to run this visitor
        uncached_visitor_names.push(visitor_name)
      end
    end

    uncached_visitor_names
  end

  def get_cached_value(book_part, visitor_name)
    return nil if cached_attribute(visitor_name).nil?

    # Rails casts nil values to the empty form of the serialized attribute, e.g. {} for a Hash,
    # so if it is empty, return nil so the visitor actually runs.  If the actual cached value is
    # empty (rare), it is no loss to actually run the visitor.

    cached_value = book_part.send(cached_attribute(visitor_name))
    cached_value.empty? ? nil : cached_value
  end

  def set_cached_value(book_part, visitor_name, value)
    return if cached_attribute(visitor_name).nil?
    book_part.update_attribute(cached_attribute(visitor_name), value)
  end

  def cached_attribute(visitor_name)
    VISITOR_INFO[visitor_name][:cached_attribute]
  end

  def process_uncached_visitors(book_part, visitor_names)
    visitors = map_visitor_names_to_visitors(visitor_names)

    # Kick off the recursive visitation
    visit_book_part(book_part, visitors)

    replace_outputs_with_visited_output(book_part, visitor_names)
  end

  def map_visitor_names_to_visitors(visitor_names)
    visitor_names.collect do |name|
      outputs[name] = VISITOR_INFO[name][:visitor_class].new
    end
  end

  def replace_outputs_with_visited_output(book_part, visitor_names)
    # We've temporarily stored the visitor objects in the outputs
    # structure for convenience.  Now iterate back through them
    # replace them with their visited output.
    #
    # Also, this is where we cache results, if appropriate

    visitor_names.each do |name|
      visited_output = outputs[name].output
      set_cached_value(book_part, name, visited_output)
      outputs[name] = visited_output
    end
  end

  def enable_express_output_if_only_one_visitor(visitor_names)
    if visitor_names.count == 1
      outputs[:visit_book_part] = outputs[visitor_names.first]
    end
  end

  def verify_valid_visitor_names(visitor_names)
    if (VISITOR_INFO.keys & visitor_names).length != visitor_names.length
      raise "undefined visitor in #{visitor_names}. Try one of toc, exercises, page_data"
    end
  end

  # The visitation methods
  #
  # We made an explicit choice to not dirty up the BookPart and Page classes,
  # and instead put the visitation methods here.

  def visit_book_part(book_part, visitors)
    child_book_part_includes, page_includes = set_visitor_defined_includes(
      book_part, visitors
    )

    # We use the `descend` / `ascend` hooks to explicitly tell visitors to move
    # down / up a level if they are tracking levels.

    visitors.each(&:descend)
    visit_pages(book_part, page_includes, visitors)
    visit_book_parts(book_part, child_book_part_includes, visitors)
    visitors.each(&:ascend)
  end

  def visit_page(page, visitors)
    visitors.each do |visitor|
      visitor.visit_page(page)
    end
  end

  def visit_pages(book_part, includes, visitors)
    book_part.pages.includes(includes.uniq).each do |page|
      visit_page(page, visitors)
    end
  end

  def visit_book_parts(book_part, includes, visitors)
    book_part.child_book_parts.includes(includes.uniq).each do |child_book_part|
      visit_book_part(child_book_part, visitors)
    end
  end

  def set_visitor_defined_includes(book_part, visitors)
    # Let visitors define what should be included in queries of pages and
    # book parts (to be more efficient in our querying)

    child_book_part_includes = []
    page_includes = []

    visitors.each do |visitor|
      visitor.visit_book_part(book_part)
      child_book_part_includes.push(visitor.book_part_includes)
      page_includes.push(visitor.page_includes)
    end

    return child_book_part_includes, page_includes
  end

end
