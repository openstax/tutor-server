class Content::Routines::UpdatePageContent

  lev_routine

  protected

  def exec(pages:)
    # Get all page uuids in this book
    page_uuids = pages.collect{ |page| page.uuid }

    pages.each do |page|
      doc = Nokogiri::HTML(page.content)
      doc.css('[src],[href]').each do |link|
        attr = link.attribute('src') || link.attribute('href')
        path = URI.parse(attr.value).path

        change_page_links(path, page_uuids, attr)
      end

      page.content = doc.to_html
      # Maybe replace with UPSERT once we have support for it
      # https://wiki.postgresql.org/wiki/UPSERT
      page.save!
    end

    outputs[:pages] = pages
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
end
