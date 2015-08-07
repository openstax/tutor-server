module Ecosystem
  module Strategies
    module Direct
      class Exercise < Entity

        wraps ::Content::Models::Exercise

        exposes :page, :url, :title, :content, :uid, :number, :version

        alias_method :entity_page, :page
        def page
          ::Ecosystem::Page.new(strategy: entity_page)
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

      end
    end
  end
end
