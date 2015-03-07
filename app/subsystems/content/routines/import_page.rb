class Content::ImportPage

  TUTOR_HOST = 'http://localhost:3001'
  TUTOR_ATTACHMENTS_URL = "#{TUTOR_HOST}/attachments"
  TUTOR_ATTACHMENTS_PATH = 'public/attachments'

  # This XPath currently tests for a node
  # with a class that starts with ost-topic
  LO_XPATH = "//*[contains(concat(' ', @class), ' ost-tag-lo-')]/@class"

  # This Regex finds the LO within the class string
  # and ensures it is properly formatted
  LO_REGEX = /ost-tag-lo-([\w-]+-lo[\d]+)/

  lev_routine

  uses_routine Content::ImportCnxResource,
               as: :cnx_import,
               translations: { outputs: { type: :verbatim } }

  uses_routine Content::CreatePage,
               as: :create_page,
               translations: { outputs: { type: :verbatim } }

  uses_routine Content::TagResourceWithTopics,
               as: :add_lo,
               translations: { outputs: { type: :verbatim } }

  uses_routine Content::ImportExercises,
               as: :import_exercises,
               translations: { outputs: { scope: :exercises } }

  protected

  # Creates or erases a file, then writes the content to it
  def write(filename, content)
    open(filename, 'wb') do |file|
      file.write(content)
    end
  end

  # Gets a file from a url and saves it locally
  def download(url, filename)
    Dir.mkdir TUTOR_ATTACHMENTS_PATH \
      unless File.exists? TUTOR_ATTACHMENTS_PATH
    destination = "#{TUTOR_ATTACHMENTS_PATH}/#{filename}"
    write(destination, http_get(url))
    "#{TUTOR_ATTACHMENTS_URL}/#{filename}"
  end

  # Imports and saves a CNX page as a Page into the given Book
  # Returns the Resource object, a Page object and
  # the JSON hash used to create them
  def exec(id:, book_part:, path: nil, options: {})
    run(:cnx_import, id, options)
    hash = outputs[:hash]

    run(:create_page, url: outputs[:url],
                      content: outputs[:content],
                      book_part: book_part,
                      path: path,
                      title: hash['title'] || '')
    transfer_errors_from(outputs[:page], {type: :verbatim}, true)

    book_part.pages << outputs[:page] unless book_part.nil?
    transfer_errors_from outputs[:page], {type: :verbatim}, true

    # Extract LO's
    los = outputs[:doc].xpath(LO_XPATH).collect do |node|
      LO_REGEX.match(node.value).try(:[], 1)
    end.compact.uniq

    # Tag Page with LO's
    run(:add_lo, outputs[:page], los)

    # Get Exercises from OSE that match the LO's
    run(:import_exercises, tag: los)
  end

end
