require 'addressable/uri'
require 'open-uri'

require_relative './v1/custom_css'

require_relative './v1/fragment'
require_relative './v1/fragment/embedded'
require_relative './v1/fragment/video'
require_relative './v1/fragment/interactive'
require_relative './v1/fragment/reading'
require_relative './v1/fragment/exercise'
require_relative './v1/fragment/optional_exercise'
require_relative './v1/fragment_splitter'

require_relative './v1/book'
require_relative './v1/book_part'
require_relative './v1/page'

module OpenStax::Cnx::V1

  extend MonitorMixin

  class << self

    def configure
      yield self
    end

    # Sets the archive URL base. Forces https. Not thread-safe, use with_archive_url instead.
    def archive_url_base=(url)
      synchronize do
        uri = Addressable::URI.parse(url)
        uri.scheme = 'https'

        @@archive_url_base = uri.to_s
      end
    end

    # Reads the archive URL base. Thread-safe.
    def archive_url_base
      synchronize{ @@archive_url_base }
    end

    # Temporarily sets the archive URL base. Thread-safe due to monitors.
    def with_archive_url(url)
      synchronize do
        begin
          old_url = archive_url_base
          self.archive_url_base = url

          yield
        ensure
          self.archive_url_base = old_url
        end
      end
    end

    def webview_url_base
      archive_url_base.sub(/archive[\.-]?/, '')
    end

    # Archive url for the given path
    # Forces /contents/ to be prepended to the path, unless the path begins with /
    def archive_url_for(path)
      Addressable::URI.join(archive_url_base, '/contents/', path).to_s
    end

    # Webview url for the given path
    # Forces /contents/ to be prepended to the path, unless the path begins with /
    def webview_url_for(path)
      Addressable::URI.join(webview_url_base, '/contents/', path).to_s
    end

    def fetch(id)
      url = archive_url_for(id)

      begin
        Rails.logger.debug { "Fetching #{url}" }
        JSON.parse open(url, 'ACCEPT' => 'text/json').read
      rescue OpenURI::HTTPError => exception
        raise OpenStax::HTTPError, "#{exception.message} for URL #{url}"
      end
    end

    def book(options = {})
      OpenStax::Cnx::V1::Book.new(options)
    end

  end

end
