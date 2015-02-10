class GetCnxJson

  CNX_ARCHIVE_URL_BASE = 'http://archive.cnx.org'
  CNX_ARCHIVE_URL = "#{CNX_ARCHIVE_URL_BASE}/contents"

  lev_routine

  protected

  # Imports a CNX page as a hash
  # Returns the hash and the CNX url (including version information)
  def exec(id, options = {})
    url = "#{CNX_ARCHIVE_URL}/#{id}"
    json = open(url, 'ACCEPT' => 'text/json') { |f| f.read }
    hash = JSON.parse(json).merge(options)
    outputs[:hash] = hash
    outputs[:url] = "#{CNX_ARCHIVE_URL}/#{hash['id']}@#{hash['version']}"
  end

end
