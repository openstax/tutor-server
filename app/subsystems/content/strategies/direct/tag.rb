module Content
  module Strategies
    module Direct
      class Tag < Entity

        wraps ::Content::Models::Tag

        exposes :value, :tag_type, :name, :description, :book_location, :data, :visible?

      end
    end
  end
end
