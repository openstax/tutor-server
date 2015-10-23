module Catalog
  class Offering

    include Wrapper

    wrap_attributes ::Catalog::Models::Offering,
       :id, :identifier, :is_tutor, :is_concept_coach, :description, :webview_url, :pdf_url

    def ecosystem
      verify_and_return @strategy.ecosystem, allow_nil: true, klass: ::Content::Ecosystem, error: StrategyError
    end

    def content_ecosystem_id
      verify_and_return @strategy.content_ecosystem_id, allow_nil: true, klass: Integer, error: StrategyError
    end


  end
end
