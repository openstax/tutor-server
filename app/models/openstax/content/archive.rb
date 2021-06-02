class OpenStax::Content::Archive
  def initialize(version)
    content_secrets = Rails.application.secrets.openstax[:content]
    @version = version
    @slugs = {}
  end

  def base_url
    @base_url ||= begin
      content_secrets = Rails.application.secrets.openstax[:content]
      "https://#{content_secrets[:domain]}/#{content_secrets[:archive_path]}/#{@version}"
    end
  end

  def url_for(object)
    return if object.nil?

    begin
      uri = Addressable::URI.parse object
    rescue Addressable::URI::InvalidURIError
      begin
        uri = Addressable::URI.parse "/#{object}"
      rescue Addressable::URI::InvalidURIError
        Rails.logger.warn { "Invalid url: \"#{object}\" in archive link" }

        return object
      end
    end

    if uri.absolute?
      Rails.logger.warn do
        "#{self.class.name} received an unexpected absolute URL in url_for: \"#{object}\""
      end

      # Force absolute URLs to be https
      uri.scheme = 'https'
      return uri.to_s
    end

    if uri.path.blank?
      Rails.logger.warn do
        "#{self.class.name} received an unexpected fragment-only URL in url_for: \"#{object}\""
      end

      return object
    end

    if uri.path.starts_with?('../')
      uri.path = uri.path.sub('..', '')
      "#{base_url}#{uri.to_s}"
    else
      uri.path = "#{uri.path.chomp('.json').chomp('.xhtml')}.json"

      uri.path.starts_with?('/') ? "#{base_url}/contents#{uri.to_s}" :
                                   "#{base_url}/contents/#{uri.to_s}"
    end
  end

  def fetch(object)
    url = url_for object
    Rails.logger.debug { "Fetching #{url}" }
    Faraday.get(url).body
  end

  def json(object)
    begin
      JSON.parse(fetch(object)).tap do |hash|
        @slugs[object] = hash['slug']
      end
    rescue JSON::ParserError => err
      raise "OpenStax Content Archive returned invalid JSON for #{url_for object}: #{err.message}"
    end
  end

  def s3
    @s3 ||= OpenStax::Content::S3.new
  end

  def add_latest_book_version_if_missing(object)
    book_id, page_id = object.split(':', 2)
    book_uuid, book_version = book_id.split('@', 2)
    return object unless book_version.nil? && s3.bucket_configured?

    s3.ls(@version).each do |book|
      uuid, version = book.split('@')
      next unless uuid == book_uuid

      book_version = version
      break
    end

    book_id = "#{book_uuid}@#{book_version}".chomp('@')
    "#{book_id}:#{page_id}".chomp(':')
  end

  def slug(object)
    @slugs[object] ||= begin
      object_with_version = add_latest_book_version_if_missing object
      slug = json(object_with_version)['slug']
      @slugs[object_with_version] = slug if object_with_version != object
      slug
    end
  end
end
