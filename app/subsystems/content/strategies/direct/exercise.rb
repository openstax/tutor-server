module Content
  module Strategies
    module Direct
      class Exercise < Entity

        wraps ::Content::Models::Exercise

        exposes :page, :tags, :los, :aplos, :url, :title, :preview, :context, :content, :uuid,
                :group_uuid, :number, :version, :uid, :content_hash, :pool_types, :is_excluded,
                :is_multipart?, :has_interactive, :has_video, :content_as_independent_questions,
                :feature_ids

        def to_model
          repository
        end

        alias_method :entity_page, :page
        def page
          ::Content::Page.new(strategy: entity_page)
        end

        alias_method :entity_tags, :tags
        def tags
          entity_tags.map{ |et| ::Content::Tag.new(strategy: et) }
        end

        alias_method :entity_los, :los
        def los
          entity_los.map{ |el| ::Content::Tag.new(strategy: el) }
        end

        alias_method :entity_aplos, :aplos
        def aplos
          entity_aplos.map{ |ea| ::Content::Tag.new(strategy: ea) }
        end

        alias_method :string_uuid, :uuid
        def uuid
          ::Content::Uuid.new(string_uuid)
        end

        alias_method :string_group_uuid, :group_uuid
        def group_uuid
          ::Content::Uuid.new(string_group_uuid)
        end

      end
    end
  end
end
