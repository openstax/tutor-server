module Content
  module Strategies
    module Direct
      class Tag < Entitee

        wraps ::Content::Models::Tag

        exposes :ecosystem, :value, :tag_type, :name, :description,
                :book_location, :data, :visible?, :teks_tags

        alias_method :entity_ecosystem, :ecosystem
        def ecosystem
          ::Content::Ecosystem.new(strategy: entity_ecosystem)
        end

        alias_method :entity_teks_tags, :teks_tags
        def teks_tags
          entity_teks_tags.map do |entity_teks_tag|
            ::Content::Tag.new(strategy: entity_teks_tag)
          end
        end

      end
    end
  end
end
