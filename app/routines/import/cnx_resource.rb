module Import
  class CnxResource

    CNX_ARCHIVE_URL_BASE = 'http://archive.cnx.org'
    CNX_ARCHIVE_URL = "#{CNX_ARCHIVE_URL_BASE}/contents"

    lev_routine

    protected

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

    # Imports a CNX page as a Resource
    # Returns the Resource, its JSON hash, the Nokogiri doc and
    # the url retrieved from CNX (including version information)
    def exec(id, options = {})
      url = "#{CNX_ARCHIVE_URL}/#{id}"
      json = open(url, 'ACCEPT' => 'text/json') { |f| f.read }
      hash = JSON.parse(json).merge(options)
      outputs[:hash] = hash
      cnx_id = hash['id'] || id
      version = "@#{hash['version']}" unless hash['version'].blank?
      url = "#{CNX_ARCHIVE_URL}/#{cnx_id}#{version}"
      outputs[:url] = url

      if options[:book]
        content = hash['tree'].try(:[], 'contents').try(:to_json) || ''
        outputs[:doc] = nil
      else
        doc = Nokogiri::HTML(hash['content'] || '')
        outputs[:doc] = doc
        content = convert(doc, url)
      end

      resource = Resource.find_or_initialize_by(url: url)
      resource.cached_content = content
      resource.save
      outputs[:resource] = resource

      transfer_errors_from resource, type: :verbatim
    end

  end
end
