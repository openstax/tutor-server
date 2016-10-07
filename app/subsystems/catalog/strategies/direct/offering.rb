module Catalog
  module Strategies
    module Direct
      class Offering < Entity

        wraps ::Catalog::Models::Offering

        exposes :id, :salesforce_book_name, :appearance_code,
                :is_tutor, :is_concept_coach, :description,
                :webview_url, :pdf_url, :ecosystem, :content_ecosystem_id,
                :default_course_name

        def self.find_by(*args)
          model = ::Catalog::Models::Offering.where(*args).take
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
