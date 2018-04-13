class Content::Routines::UpdatePageContent

  # Extract the uuid and version from paths like:
  #   /contents/127f63f7-d67f-4710-8625-2b1d4128ef6b
  #   /contents/127f63f7-d67f-4710-8625-2b1d4128ef6b@3
  #   /contents/127f63f7-d67f-4710-8625-2b1d4128ef6b@3#figure-1
  #   /contents/031da8d3-b525-429c-80cf-6c8ed997733a@9.98:127f63f7-d67f-4710-8625-2b1d4128ef6b@3

  CNX_ID_REGEX_STRING = <<-LINK_REGEX.strip_heredoc.gsub(/[\s\t]*/, '')
    /contents/
    (?:([0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12})(?:@([\\d\\.]+))?:)?
    ([0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12})(?:@([\\d\\.]+))?
  LINK_REGEX
  CNX_ID_REGEX = Regexp.new(CNX_ID_REGEX_STRING, Regexp::IGNORECASE)

  lev_routine

  protected

  def exec(book:, pages:, save: true)
    # Get all page uuids and cnx_ids given
    pages_by_uuid = pages.index_by(&:uuid)

    pages.each do |page|
      doc = Nokogiri::HTML(page.content)
      doc.css('[href]').each do |link|
        href_attr = link.attribute('href')
        change_page_link(href_attr, book, pages_by_uuid)
      end

      page.content = doc.to_html

      # Replace individual saves with bulk UPSERT once we have support for it
      page.save! if save
    end

    outputs.pages = pages
  end

  # If the link goes to a page in the book, change the link to just the page's book_location
  def change_page_link(href_attr, book, pages_by_uuid)
    url = Addressable::URI.parse(href_attr.value) rescue return
    path = url.path
    matches = CNX_ID_REGEX.match(path)

    # Abort if cnx_id not found
    return if matches.nil?

    book_uuid = matches[1]
    book_version = matches[2]
    page_uuid = matches[3]
    page_version = matches[4]
    page = pages_by_uuid[page_uuid]

    # Abort if another book or book version was linked
    return if (book_uuid.present? && book.uuid != book_uuid) ||
              (book_version.present? && book.version != book_version)

    # Change the link back to a relative link
    url.scheme = nil
    url.host = nil

    # Update the path according to if this is a book link or a page link
    url.path = if page.nil?
      # Check if the page_uuid/page_version are actually the book's
      return if (book.uuid != page_uuid) ||
                (page_version.present? && book.version != page_version)

      # The link actually points to the book itself
      # Remove the path from the link
      "/books/#{book.ecosystem.id}"
    else
      # Check if the page's version is correct
      return if page_version.present? && page.version != page_version

      # Change the link's path to the page's book_location
      "/books/#{book.ecosystem.id}/section/#{page.book_location.reject(&:zero?).join('.')}"
    end

    href_attr.value = url.to_s
  end
end
