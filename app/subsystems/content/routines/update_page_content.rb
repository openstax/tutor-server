class Content::Routines::UpdatePageContent

  # Extract the uuid and version from paths like:
  #   /contents/127f63f7-d67f-4710-8625-2b1d4128ef6b
  #   /contents/127f63f7-d67f-4710-8625-2b1d4128ef6b@2
  #   /contents/127f63f7-d67f-4710-8625-2b1d4128ef6b@2#figure-1
  CNX_ID_REGEX = \
    /\/contents\/([0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12})(?:@([\d\.]+))?/i

  lev_routine

  protected

  def exec(pages:, save: true)
    # Get all page uuids and cnx_ids given
    pages_by_uuid = pages.index_by(&:uuid)

    pages.each do |page|
      doc = Nokogiri::HTML(page.content)
      doc.css('[href]').each do |link|
        href_attr = link.attribute('href')
        change_page_link(href_attr, pages_by_uuid)
      end

      page.content = doc.to_html

      # Replace individual saves with bulk UPSERT once we have support for it
      page.save! if save
    end

    outputs[:pages] = pages
  end

  # If the link goes to a page in the book, change the link to just the page's book_location
  def change_page_link(href_attr, pages_by_uuid)
    url = Addressable::URI.parse(href_attr.value)
    path = url.path
    matches = CNX_ID_REGEX.match(path)

    # Abort if cnx_id not found
    return if matches.nil?

    uuid = matches[1]
    version = matches[2]
    page = pages_by_uuid[uuid]

    # Abort if cnx_id not in the book
    return if page.nil? || (version.present? && page.version != version)

    # Change the link back to a relative link, with just the page's book_location
    url.scheme = nil
    url.host = nil
    url.path = page.book_location.reject(&:zero?).join('.')

    href_attr.value = url.to_s
  end
end
