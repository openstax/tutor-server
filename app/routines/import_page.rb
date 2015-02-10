class ImportPage

  TUTOR_HOST = 'http://localhost:3001'
  TUTOR_ATTACHMENTS_URL = "#{TUTOR_HOST}/attachments"
  TUTOR_ATTACHMENTS_PATH = 'public/attachments'

  CNX_ARCHIVE_URL_BASE = 'http://archive.cnx.org'
  CNX_ARCHIVE_URL = "#{CNX_ARCHIVE_URL_BASE}/contents"

  LO_XPATH = "//*[contains(concat(' ', normalize-space(@class)), ' ost-') and contains(substring-before(substring-after(concat(normalize-space(@class), ' '), 'ost-'), ' '), '-lo')]/@class"
  LO_REGEX = /(ost-[\w-]+-lo[\d]+)/

  lev_routine

  protected

  # Gets the contents of the given URL as JSON
  def get_json(url)
    open(url, 'ACCEPT' => 'text/json') { |f| return f.read }
  end

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

  # Changes relative URL's in the content to be absolute
  # Returns the processed content
  def convert(doc, base_url)
    # In the future (when books are readable in Tutor),
    # do the opposite (make absolute links into relative links)
    # and make sure all files are properly served
    doc.css("*[src]").each do |tag|
      uri = URI.parse(URI.escape(tag.attributes["src"].value))
      next if uri.absolute?

      tag.attributes["src"].value = URI.unescape(URI.join(base_url, uri).to_s)
    end

    doc.to_s
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

  # Imports and saves a CNX page as a Resource
  # Returns the Resource object and the JSON hash used to create it
  # Also returns a Page object if the :chapter option is set
  def exec(id, options = {})
    url = "#{CNX_ARCHIVE_URL}/#{id}"
    hash = JSON.parse(get_json(url)).merge(options.except(:chapter))
    outputs[:hash] = hash
    doc = Nokogiri::HTML(hash['content']) || ''

    outputs[:resource] = Resource.create(
      title: hash['title'],
      version: hash['version'],
      url: "#{CNX_ARCHIVE_URL}/#{hash['id']}@#{hash['version']}",
      cached_content: convert(doc, url)
    )
    transfer_errors_from outputs[:resource], scope: :resource

    return unless options[:chapter]

    outputs[:page] = Page.create(resource: outputs[:resource],
                                 chapter: options[:chapter])
    transfer_errors_from outputs[:page], scope: :page

    outputs[:page_topics] = extract_topics(doc, outputs[:page])
  end

end
