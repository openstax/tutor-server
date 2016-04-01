module Content
  module Strategies
    module Generated
      class Manifest::Book::ProcessingInstruction < Hashie::Mash

        def css
          super.to_s
        end

        def fragments
          super.to_a
        end

        def labels
          super.to_a
        end

      end
    end
  end
end
