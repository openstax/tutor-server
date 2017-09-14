module Catalog
  module Strategies
    module Direct
      class Offering < Entitee

        wraps ::Catalog::Models::Offering

        exposes :id, :number, :salesforce_book_name, :appearance_code,
                :is_tutor, :is_concept_coach, :is_available, :title, :description,
                :webview_url, :pdf_url, :ecosystem, :content_ecosystem_id, :default_course_name,
                :does_cost

        def self.find_by(*args)
          model = ::Catalog::Models::Offering.find_by(*args)
          return if model.nil?

          ::Catalog::Offering.new(strategy: new(model))
        end

        alias_method :entity_ecosystem, :ecosystem
        def ecosystem
          eco = entity_ecosystem
          eco.nil? ? nil : ::Content::Ecosystem.new(strategy: eco)
        end

        def to_model
          repository
        end

      end
    end
  end
end
