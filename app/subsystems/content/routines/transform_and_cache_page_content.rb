# This routine handles transforms that require a saved page, such as links containing the page id
# The page content changes, fragments and snap labs are then cached
class Content::Routines::TransformAndCachePageContent
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

  def exec(book:, pages: nil, save: true)
    pages ||= book.pages.to_a

    # Get all page uuids and cnx_ids given
    pages_by_uuid = pages.index_by(&:uuid)

    # Get all exercises that require context
    context_exercises = Content::Models::Exercise.requires_context.where(
      id: pages.flat_map(&:all_exercise_ids)
    ).preload(:tags).to_a
    context_exercises_by_page_id = context_exercises.group_by(&:content_page_id)

    pages.each do |page|
      doc = Nokogiri::HTML(page.content)
      doc.css('[href]').each do |link|
        # Transforms absolute CNX urls to absolute reference view URLs
        # If the link goes to a page in the book, change the link to just the page's link
        href_attr = link.attribute('href')
        uri = Addressable::URI.parse(href_attr.value) rescue next
        path = uri.path
        matches = CNX_ID_REGEX.match(path)

        # Abort if cnx_id not found
        next if matches.nil?

        book_uuid = matches[1]
        book_version = matches[2]
        target_page_uuid = matches[3]
        target_page_version = matches[4]
        target_page = pages_by_uuid[target_page_uuid]

        # Abort if another book or book version was linked
        next if (book_uuid.present? && book.uuid != book_uuid) ||
                (book_version.present? && book.version != book_version)

        # Change the link back to a relative link
        uri.scheme = nil
        uri.host = nil

        # Update the path according to if this is a book link or a page link
        uri.path = if target_page.nil?
          # Check if the page_uuid/page_version are actually the book's
          next if (book.uuid != target_page_uuid) ||
                  (target_page_version.present? && book.version != target_page_version)

          # The link actually points to the book itself
          # Remove the path from the link
          book.reference_view_url
        else
          # Check if the page's version is correct
          next if target_page_version.present? && target_page.version != target_page_version

          # Change the link's path to the page's book_location
          target_page.reference_view_url book: book
        end

        href_attr.value = uri.to_s
      end

      page.content = doc.to_html
      page.cache_fragments_and_snap_labs

      # Assign exercise context if required
      (context_exercises_by_page_id[page.id] || []).each do |context_exercise|
        feature_ids = context_exercise.feature_ids
        context_exercise.context = page.context_for_feature_ids feature_ids

        if context_exercise.context.blank?
          if feature_ids.empty?
            Rails.logger.warn do
              "Exercise #{context_exercise.uid} requires context but it has no feature ID tags"
            end
          else
            Rails.logger.warn do
              "Exercise #{context_exercise.uid} requires context but its feature ID(s) [ #{
                feature_ids.join(', ')} ] could not be found on #{page.url}"
            end
          end
        end
      end
    end

    outputs.pages = pages

    return unless save

    # Pages are large enough that saving them individually seems faster than importing
    pages.each(&:save!)

    context_exercises.each(&:save!)
  end
end
