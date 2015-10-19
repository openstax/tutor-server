module Catalog
  module Strategies
    module Direct
      class Offering < Entity

        wraps ::Catalog::Models::Offering

        exposes :identifier, :flags, :description, :webview_url

      end
    end
  end
end
