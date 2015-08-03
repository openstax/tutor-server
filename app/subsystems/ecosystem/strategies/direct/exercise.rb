module Ecosystem
  module Strategies
    class Direct
      class Exercise < Entity

        wraps ::Content::Models::Exercise

        exposes :url, :title, :content, :uid, :los, :aplos, :tag_hashes

        exposes :find, from_class: ::Content::Models::Exercise

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
