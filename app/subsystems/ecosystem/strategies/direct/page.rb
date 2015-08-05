module Ecosystem
  module Strategies
    module Direct
      class Page < Entity

        wraps ::Content::Models::Page

        exposes :chapter, :url, :title, :content, :book_location, :is_intro?, :fragments

        alias_method :entity_chapter, :chapter
        def chapter
          ::Ecosystem::Chapter.new(strategy: entity_chapter)
        end

        def tags
          repository.tags.collect{ |t| t.value }
        end

        def los
          repository.los.collect{ |t| t.value }
        end

        def aplos
          repository.aplos.collect{ |t| t.value }
        end

        def related_content(title: nil, book_location: nil)
          title ||= self.title
          book_location ||= self.book_location
          { title: title, book_location: book_location }
        end

      end
    end
  end
end
