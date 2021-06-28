module Content
  class Manifest::Book < OpenStruct
    def to_h
      super.deep_stringify_keys
    end

    def archive_version
      super.to_s
    end

    def version
      super.to_s
    end

    def reading_processing_instructions
      super.to_a
    end

    def errors
      return @errors unless @errors.nil?

      @errors = []
      @errors << 'Manifest Book has no uuid' if uuid.blank?

      @errors
    end

    def valid?
      errors.empty?
    end
  end
end
