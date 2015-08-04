module Ecosystem
  module Strategies
    module Direct
      class Page < Entity

        wraps ::Content::Models::Page

        exposes :book_part, :url, :title, :content,
                :chapter_section, :is_intro?, :fragments, :los, :aplos

        exposes :find, from_class: ::Content::Models::Page

        def chapter
          ::Ecosystem::Chapter.new(strategy: book_part)
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

        def related_content(title: nil, chapter_section: nil)
          title ||= self.title
          chapter_section ||= self.chapter_section
          { title: title, chapter_section: chapter_section }
        end

      end
    end
  end
end
