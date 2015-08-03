module Ecosystem
  module Strategies
    class Direct
      class Page < Entity

        wraps ::Content::Models::Page

        exposes :url, :title, :content, :chapter_section, :book_part,
                :is_intro?, :fragments, :los, :aplos

        exposes :find, from_class: ::Content::Models::Page

        def tags
          repository.tags.collect{ |t| t.value }
        end

        def los
          repository.los.collect{ |t| t.value }
        end

        def aplos
          repository.aplos.collect{ |t| t.value }
        end

      end
    end
  end
end
