module Catalog
  class Offering

    include Wrapper

    self.strategy_class = Catalog::Strategies::Direct::Offering

    wrap_attributes ::Catalog::Models::Offering,
       :id, :salesforce_book_name, :appearance_code, :is_tutor, :is_concept_coach,
       :description, :webview_url, :pdf_url, :default_course_name

    def ecosystem
      verify_and_return @strategy.ecosystem, allow_nil: true, klass: ::Content::Ecosystem, error: StrategyError
    end

    def content_ecosystem_id
      verify_and_return @strategy.content_ecosystem_id, allow_nil: true, klass: Integer, error: StrategyError
    end

    def self.find_by(*args)
      verify_and_return strategy_class.find_by(*args), klass: self,
                                                       error: StrategyError,
                                                       allow_nil: true
    end

  end
end
