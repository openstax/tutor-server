module Content
  class Exercise

    include Wrapper

    def id
      verify_and_return @strategy.id, klass: Integer, error: StrategyError
    end

    def url
      verify_and_return @strategy.url, klass: String, error: StrategyError
    end

    def uuid
      verify_and_return @strategy.uuid, klass: String, error: StrategyError
    end

    def group_uuid
      verify_and_return @strategy.group_uuid, klass: String, error: StrategyError
    end

    def number
      verify_and_return @strategy.number, klass: Integer, error: StrategyError
    end

    def version
      verify_and_return @strategy.version, klass: Integer, error: StrategyError
    end

    def uid
      verify_and_return @strategy.uid, klass: String, error: StrategyError
    end

    def title
      verify_and_return @strategy.title, klass: String, allow_nil: true, error: StrategyError
    end

    def preview
      verify_and_return @strategy.preview, klass: String, allow_blank: true, error: StrategyError
    end

    def context
      verify_and_return @strategy.context, klass: String, allow_blank: true, error: StrategyError
    end

    def content
      verify_and_return @strategy.content, klass: String, error: StrategyError
    end

    def content_hash
      verify_and_return @strategy.content_hash, klass: Hash, error: StrategyError
    end

    def content_as_independent_questions
      verify_and_return @strategy.content_as_independent_questions, klass: Array,
                                                                    error: StrategyError
    end

    def tags
      verify_and_return @strategy.tags, klass: ::Content::Tag, error: StrategyError
    end

    def los
      verify_and_return @strategy.los, klass: ::Content::Tag, error: StrategyError
    end

    def aplos
      verify_and_return @strategy.aplos, klass: ::Content::Tag, error: StrategyError
    end

    def feature_ids
      verify_and_return @strategy.feature_ids, klass: String, error: StrategyError
    end

    def page
      verify_and_return @strategy.page, klass: ::Content::Page, error: StrategyError
    end

    def pool_types
      verify_and_return @strategy.pool_types, klass: String, allow_nil: true, error: StrategyError
    end

    def is_excluded
      return if @strategy.is_excluded.nil?
      !!@strategy.is_excluded
    end

    def is_multipart?
      !!@strategy.is_multipart?
    end

    def has_interactive
      !!@strategy.has_interactive
    end

    def has_video
      !!@strategy.has_video
    end

    def to_model
      @strategy.to_model
    end

  end
end
