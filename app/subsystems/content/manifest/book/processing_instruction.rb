module Content
  class Manifest
    class Book
      class ProcessingInstruction

        include Wrapper

        def to_h
          verify_and_return @strategy.to_h, klass: Hash, error: StrategyError
        end

        def css
          verify_and_return @strategy.css, klass: String, error: StrategyError
        end

        def fragments
          verify_and_return @strategy.fragments, klass: String, error: StrategyError
        end

        def labels
          verify_and_return @strategy.labels, klass: String, error: StrategyError
        end

      end
    end
  end
end
