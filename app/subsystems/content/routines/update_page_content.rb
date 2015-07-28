class Content::Routines::UpdatePageContent

  lev_routine

  protected

  def exec(book_part:)
    # Get all page uuids in this book
    pages = []
    get_pages(book_part, pages)
    page_uuids = pages.collect { |page| page.uuid }

    pages.each do |page|
      doc = Nokogiri::HTML(page.content)
      doc.css('[src],[href]').each do |link|
        attr = link.attribute('src') || link.attribute('href')
        path = URI.parse(attr.value).path

        change_page_links(path, page_uuids, attr)
      end

      page.update_attributes(content: doc.to_html)
    end
  end

  def change_page_links(path, page_uuids, attr)
    # if the link goes to a page in the book, change the link to just <uuid><rest-of-path>

    # if the path starts with /contents/
    if path.starts_with?('/contents/')
      # extract the uuid from paths like:
      #   /contents/127f63f7-d67f-4710-8625-2b1d4128ef6b@2
      #   /contents/127f63f7-d67f-4710-8625-2b1d4128ef6b
      #   /contents/127f63f7-d67f-4710-8625-2b1d4128ef6b@2#figure-1
      uuid = path.split(/\/|@|#/)[2]

      # and the uuid is in the book
      if page_uuids.include?(uuid)
        # change the link to a relative link, with just <uuid><rest-of-path>
        attr.value = path.gsub(/^\/contents\//, '')
      end
    end
  end

  def get_pages(book_part, result)
    book_part.pages.each do |page|
      result << page
    end
    book_part.child_book_parts.each do |book_part|
      get_pages(book_part, result)
    end
  end
end
