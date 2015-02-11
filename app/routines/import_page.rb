class ImportPage

  TUTOR_HOST = 'http://localhost:3001'
  TUTOR_ATTACHMENTS_URL = "#{TUTOR_HOST}/attachments"
  TUTOR_ATTACHMENTS_PATH = 'public/attachments'

  LO_XPATH = "//*[contains(concat(' ', normalize-space(@class)), ' ost-') and contains(substring-before(substring-after(concat(normalize-space(@class), ' '), 'ost-'), ' '), '-lo')]/@class"
  LO_REGEX = /(ost-[\w-]+-lo[\d]+)/

  lev_routine

  uses_routine ImportCnxResource,
               as: :cnx_import, translations: { outputs: { type: :verbatim } }

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

  # Finds LO's that appear in the content body using a matcher
  # Finds or creates a Topic for each LO
  # Returns the array of PageTopics created
  def extract_topics(doc, page)
    los = doc.xpath(LO_XPATH).collect do |node|
      LO_REGEX.match(node.value).try(:[], 0)
    end.compact.uniq

    los.collect do |lo|
      topic = Topic.find_or_create_by(name: lo)
      transfer_errors_from(topic, scope: :topic)
      pt = PageTopic.find_or_create_by(page: page, topic: topic)
      transfer_errors_from(pt, scope: :page_topic)
      pt
    end
  end

  # Imports and saves a CNX page as a Page into the given Book
  # Returns the Resource object, a Page object and
  # the JSON hash used to create them
  def exec(id, book, options = {})
    run(:cnx_import, id, options)
    hash = outputs[:hash]

    outputs[:page] = Page.create(resource: outputs[:resource],
                                 book: book,
                                 title: hash['title'] || '')
    book.pages << outputs[:page] unless book.nil?
    transfer_errors_from outputs[:page], type: :verbatim

    outputs[:page_topics] = extract_topics(outputs[:doc], outputs[:page])
  end

end
