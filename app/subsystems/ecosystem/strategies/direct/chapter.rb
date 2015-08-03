module Ecosystem
  module Strategies
    class Direct
      class Chapter < Entity

        wraps ::Content::Models::BookPart

        exposes :title, :pages

        alias_method :entity_pages, :pages
        def pages
          entity_pages.collect do |entity_page|
            ::Ecosystem::Page.new(strategy: entity_page)
          end
        end

      end
    end
  end
end
