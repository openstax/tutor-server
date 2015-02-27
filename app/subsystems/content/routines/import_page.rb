class Content::ImportPage

  TUTOR_HOST = 'http://localhost:3001'
  TUTOR_ATTACHMENTS_URL = "#{TUTOR_HOST}/attachments"
  TUTOR_ATTACHMENTS_PATH = 'public/attachments'

  # This XPath currently tests for a section
  # with a class that starts with ost and a class that ends with -lo(number)
  # It does not require the 2 classes to be the same
  LO_XPATH = "/html/body/section[contains(concat(' ', @class), ' ost') and string(number(substring-before(substring-after(concat(@class, ' '), '-lo'), ' '))) != 'NaN']/@class"

  # This Regex finds the LO within the class string
  # and ensures it is properly formatted
  LO_REGEX = /(ost[\w-]+-lo[\d]+)/

  lev_routine

  uses_routine Content::ImportCnxResource,
               as: :cnx_import,
               translations: { outputs: { type: :verbatim } }

  uses_routine Content::TagResourceWithTopics,
               as: :tag,
               translations: { outputs: { type: :verbatim } }

  uses_routine Content::CreatePage,
               as: :create_page,
               translations: { outputs: { type: :verbatim } }

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
  def exec(id, book, options = {})
    run(:cnx_import, id, options)
    hash = outputs[:hash]

    run(:create_page, url: outputs[:url],
                      content: outputs[:content],
                      book: book,
                      title: hash['title'])

    book.pages << outputs[:page] unless book.nil?
    transfer_errors_from outputs[:page], type: :verbatim

    los = outputs[:doc].xpath(LO_XPATH).collect do |node|
      LO_REGEX.match(node.value).try(:[], 0)
    end.compact.uniq

    run(:tag, outputs[:page], los)
  end

end
