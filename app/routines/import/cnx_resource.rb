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

    # Imports a CNX page
    # Returns the JSON hash, the Nokogiri doc, the url retrieved
    # from CNX (including version information) and the content
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
        outputs[:content] = hash['tree'].try(:[], 'contents')
                                        .try(:to_json) || ''
        outputs[:doc] = nil
      else
        doc = Nokogiri::HTML(hash['content'] || '')
        outputs[:doc] = doc
        outputs[:content] = convert(doc, url)
      end
    end

  end
end
