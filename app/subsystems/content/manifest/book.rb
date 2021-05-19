module Content
  class Manifest::Book < OpenStruct
    def to_h
      super.deep_stringify_keys
    end

    def reading_processing_instructions
      super.to_a
    end

    def errors
      return @errors unless @errors.nil?

      @errors = []
      @errors << 'Manifest Book has no ox_id' if ox_id.blank?

      @errors
    end

    def valid?
      errors.empty?
    end

    def update_version!
      old_ox_id = ox_id
      return if old_ox_id.nil?

      self.ox_id = old_ox_id.split('@').first
      old_ox_id
    end

    def update_exercises!
      old_exercise_ids = exercise_ids
      return if old_exercise_ids.nil?

      self.exercise_ids = old_exercise_ids.map{ |exercise_id| exercise_id.split('@').first }
      old_exercise_ids
    end

    def discard_exercises!
      delete_field(:exercise_ids) if respond_to?(:exercise_ids)
    end
  end
end
