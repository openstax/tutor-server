require 'addressable/uri'
require 'open-uri'

require_relative './v1/configuration'

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
require_relative './v1/baked'

module OpenStax::Cnx::V1

  extend Configurable

  class << self

    def new_configuration
      OpenStax::Cnx::V1::Configuration.new
    end

    def archive_url_base
      configuration.archive_url_base
    end

    def webview_url_base
      configuration.webview_url_base
    end

    def with_archive_url(url)
      begin
        old_url = archive_url_base
        self.configuration.archive_url_base = url

        yield
      ensure
        self.configuration.archive_url_base = old_url
      end
    end

    def with_webview_url(url)
      begin
        old_url = webview_url_base
        self.configuration.webview_url_base = url

        yield
      ensure
        self.configuration.webview_url_base = old_url
      end
    end

    # Archive url for the given path
    # Forces /contents/ to be prepended to the path, unless the path begins with /
    def archive_url_for(path)
      Addressable::URI.join(configuration.archive_url_base, '/contents/', path).to_s
    end

    # Webview url for the given path
    # Forces /contents/ to be prepended to the path, unless the path begins with /
    def webview_url_for(path)
      Addressable::URI.join(configuration.webview_url_base, '/contents/', path).to_s
    end

    def fetch(url)
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
