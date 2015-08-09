module Ecosystem
  module Strategies
    module Direct
      class Chapter < Entity

        wraps ::Content::Models::Chapter

        exposes :title, :pages, :book_location

        alias_method :entity_pages, :pages
        def pages
          entity_pages.collect do |entity_page|
            ::Ecosystem::Page.new(strategy: entity_page)
          end
        end

        def toc
          { title: title,
            book_location: book_location,
            pages: entity_pages.collect{ |ch| ch.toc } }
        end

      end
    end
  end
end
