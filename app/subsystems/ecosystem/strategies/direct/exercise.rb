module Ecosystem
  module Strategies
    module Direct
      class Exercise < Entity

        wraps ::Content::Models::Exercise

        exposes :page, :url, :title, :content, :uid, :los, :aplos

        def tags
          repository.tags.collect{ |t| t.value }
        end

      end
    end
  end
end
