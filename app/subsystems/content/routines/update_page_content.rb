class Content::Routines::UpdatePageContent

  lev_routine

  protected

  def exec(pages:, save: true)
    # Get all page cnx_ids given
    page_cnx_ids = pages.collect{ |page| page.cnx_id }

    pages.each do |page|
      doc = Nokogiri::HTML(page.content)
      doc.css('[href]').each do |link|
        href_attr = link.attribute('href')
        change_page_link(href_attr, page_cnx_ids)
      end

      page.content = doc.to_html
      # Maybe replace with UPSERT once we have support for it
      # https://wiki.postgresql.org/wiki/UPSERT
      page.save! if save
    end

    outputs[:pages] = pages
  end

  def change_page_link(href_attr, page_cnx_ids)
    # if the link goes to a page in the book, change the link to just <uuid><rest-of-path>
    path = URI.parse(href_attr.value).path

    # if the path starts with /contents/
    if path.starts_with?('/contents/')
      # extract the uuid from paths like:
      #   /contents/127f63f7-d67f-4710-8625-2b1d4128ef6b@2
      #   /contents/127f63f7-d67f-4710-8625-2b1d4128ef6b
      #   /contents/127f63f7-d67f-4710-8625-2b1d4128ef6b@2#figure-1
      cnx_id = path.split(/\/|#/)[2]

      # and the uuid is in the book
      if page_cnx_ids.include?(cnx_id)
        # change the link to a relative link, with just <uuid><rest-of-path>
        href_attr.value = path.gsub(/\A\/contents\//, '')
      end
    end
  end
end
