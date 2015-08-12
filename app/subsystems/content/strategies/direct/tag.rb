module Content
  module Strategies
    module Direct
      class Tag < Entity

        wraps ::Content::Models::Tag

        exposes :ecosystem, :value, :tag_type, :name, :description, :book_location, :data, :visible?

        alias_method :entity_ecosystem, :ecosystem
        def ecosystem
          ::Content::Ecosystem.new(strategy: entity_ecosystem)
        end

      end
    end
  end
end
