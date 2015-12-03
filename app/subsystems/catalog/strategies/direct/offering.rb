module Catalog
  module Strategies
    module Direct
      class Offering < Entity

        wraps ::Catalog::Models::Offering

        exposes :id, :salesforce_book_name, :appearance_code,
                :is_tutor, :is_concept_coach, :description,
                :webview_url, :pdf_url, :ecosystem, :content_ecosystem_id,
                :default_course_name

        alias_method :entity_ecosystem, :ecosystem
        def ecosystem
          entity_ecosystem ? ::Content::Ecosystem.new(strategy: entity_ecosystem) : nil
        end

        def self.find_by(*args)
          model = ::Catalog::Models::Offering.where(*args).take
          return if model.nil?

          ::Catalog::Offering.new(strategy: new(model))
        end

      end
    end
  end
end
