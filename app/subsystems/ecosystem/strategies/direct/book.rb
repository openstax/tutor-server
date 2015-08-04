module Ecosystem
  module Strategies
    module Direct
      class Book < Entity

        wraps ::Content::Models::Book

        exposes :title, :chapters, :pages

        alias_method :entity_chapters, :chapters
        def chapters
          entity_chapters.collect do |entity_chapter|
            ::Ecosystem::Chapter.new(strategy: entity_chapter)
          end
        end

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
