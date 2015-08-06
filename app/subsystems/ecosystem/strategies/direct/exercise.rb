module Ecosystem
  module Strategies
    class Direct
      class Exercise < Entity

        wraps ::Content::Models::Exercise

        exposes :pages, :url, :title, :content, :uid, :los, :aplos, :tag_hashes

        exposes :find, :find_by, from_class: ::Content::Models::Exercise

        def tags
          repository.tags.collect{ |t| t.value }
        end

        def los
          repository.los.collect{ |t| t.value }
        end

        def aplos
          repository.aplos.collect{ |t| t.value }
        end

        def related_content
          pages.collect{ |page| page.related_content }
        end

      end
    end
  end
end
