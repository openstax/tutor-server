class ImportPage

  TUTOR_HOST = 'http://localhost:3001'
  TUTOR_ATTACHMENTS_URL = "#{TUTOR_HOST}/attachments"
  TUTOR_ATTACHMENTS_PATH = 'public/attachments'

  CNX_ARCHIVE_URL_BASE = 'http://archive.cnx.org'
  CNX_ARCHIVE_URL = "#{CNX_ARCHIVE_URL_BASE}/contents"

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

  # Downloads images to Tutor and converts CNX links to Tutor links
  def convert(content)
    # TODO
    content
  end

  # Imports and saves a CNX page as a Resource
  # Returns the Resource object and the JSON hash used to create it
  # Also returns a Reading object unless the :no_reading option is set
  def exec(id, options = {})
    url = "#{CNX_ARCHIVE_URL}/#{id}"
    hash = JSON.parse(get_json(url)).merge(options.except(:no_reading))
    outputs[:hash] = hash

    outputs[:resource] = Resource.create(
      title: hash['title'],
      version: hash['version'],
      url: "#{CNX_ARCHIVE_URL}/#{hash['id']}@#{hash['version']}",
      cached_content: convert(hash['content'] || '')
    )
    transfer_errors_from outputs[:resource], scope: :resource
    return if options[:no_reading]

    outputs[:reading] = Reading.create(resource: outputs[:resource])
    transfer_errors_from outputs[:reading], scope: :reading
  end

end
