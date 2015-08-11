module Ecosystem
  module Strategies
    module Direct
      class Exercise < Entity

        wraps ::Content::Models::Exercise

        exposes :page, :tags, :los, :aplos, :url, :title, :content, :uid, :number, :version

        alias_method :entity_page, :page
        def page
          ::Ecosystem::Page.new(strategy: entity_page)
        end

        alias_method :entity_tags, :tags
        def tags
          entity_tags.collect{ |et| ::Ecosystem::Tag.new(strategy: et) }
        end

        alias_method :entity_los, :los
        def los
          entity_los.collect{ |el| ::Ecosystem::Tag.new(strategy: el) }
        end

        alias_method :entity_aplos, :aplos
        def aplos
          entity_aplos.collect{ |ea| ::Ecosystem::Tag.new(strategy: ea) }
        end

      end
    end
  end
end
