module Ecosystem
  module Strategies
    module Direct
      class Chapter < Entity

        wraps ::Content::Models::Chapter

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
