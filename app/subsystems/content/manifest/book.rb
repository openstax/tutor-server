module Content
  class Manifest
    class Book

      include Wrapper

      def to_h
        verify_and_return @strategy.to_h, klass: Hash, error: StrategyError
      end

      def archive_url
        verify_and_return @strategy.archive_url, klass: String, error: StrategyError,
                                                 allow_nil: true
      end

      def cnx_id
        verify_and_return @strategy.cnx_id, klass: String, error: StrategyError
      end

      def reading_processing_instructions
        verify_and_return @strategy.reading_processing_instructions, klass: Hash,
                                                                     error: StrategyError
      end

      def exercise_ids
        verify_and_return @strategy.exercise_ids, klass: String, error: StrategyError,
                                                  allow_nil: true
      end

      def valid?
        !!@strategy.valid?
      end

      def update_version!
        verify_and_return @strategy.update_version!, klass: self.class, error: StrategyError
      end

      def unlock_exercises!
        verify_and_return @strategy.unlock_exercises!, klass: self.class, error: StrategyError
      end

    end
  end
end
