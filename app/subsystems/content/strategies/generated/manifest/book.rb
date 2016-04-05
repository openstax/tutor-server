module Content
  module Strategies
    module Generated
      class Manifest::Book < OpenStruct

        def to_h
          super.deep_stringify_keys
        end

        def reading_processing_instructions
          super.to_a
        end

        def valid?
          cnx_id.present? && (exercise_ids || []).all?{ |ex_id| ex_id.is_a? String }
        end

        def update_version!
          self.cnx_id = cnx_id.split('@').first
          ::Content::Manifest::Book.new(strategy: self)
        end

        def unlock_exercises!
          delete_field(:exercise_ids)
          ::Content::Manifest::Book.new(strategy: self)
        end

      end

    end
  end
end
