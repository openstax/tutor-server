module Content
  module Strategies
    module Direct
      class Exercise < Entity

        wraps ::Content::Models::Exercise

        exposes :page, :tags, :los, :aplos, :url, :title, :content, :uid,
                :number, :version, :content_hash, :pool_types, :is_excluded

        alias_method :entity_page, :page
        def page
          ::Content::Page.new(strategy: entity_page)
        end

        alias_method :entity_tags, :tags
        def tags
          entity_tags.collect{ |et| ::Content::Tag.new(strategy: et) }
        end

        alias_method :entity_los, :los
        def los
          entity_los.collect{ |el| ::Content::Tag.new(strategy: el) }
        end

        alias_method :entity_aplos, :aplos
        def aplos
          entity_aplos.collect{ |ea| ::Content::Tag.new(strategy: ea) }
        end

      end
    end
  end
end
