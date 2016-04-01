module Content
  module Strategies
    module Generated
      class Manifest::Book < Hashie::Mash

        def to_h
          super.merge(
            'reading_processing_instructions' => reading_processing_instructions.map(&:to_h)
          )
        end

        def reading_processing_instructions
          super.to_a.map do |hash|
            strategy = \
              ::Content::Strategies::Generated::Manifest::Book::ProcessingInstruction.new(hash)
            ::Content::Manifest::Book::ProcessingInstruction.new(strategy: strategy)
          end
        end

        def valid?
          cnx_id.present? && (exercise_ids || []).all?{ |ex_id| ex_id.is_a? String }
        end

        def update_version!
          self.cnx_id = cnx_id.split('@').first
          ::Content::Manifest::Book.new(strategy: self)
        end

        def unlock_exercises!
          delete(:exercise_ids)
          ::Content::Manifest::Book.new(strategy: self)
        end

      end

    end
  end
end
