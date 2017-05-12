module Content
  module Strategies
    module Direct
      class Book < Entity

        wraps ::Content::Models::Book

        exposes :ecosystem, :chapters, :pages, :exercises, :tutor_uuid, :url, :archive_url,
                :webview_url, :uuid, :short_id, :version, :cnx_id, :title

        alias_method :entity_ecosystem, :ecosystem
        def ecosystem
          ::Content::Ecosystem.new(strategy: entity_ecosystem)
        end

        alias_method :entity_chapters, :chapters
        def chapters
          entity_chapters.map do |entity_chapter|
            ::Content::Chapter.new(strategy: entity_chapter)
          end
        end

        alias_method :entity_pages, :pages
        def pages
          entity_pages.map do |entity_page|
            ::Content::Page.new(strategy: entity_page)
          end
        end

        alias_method :entity_exercises, :exercises
        def exercises
          entity_exercises.map do |entity_exercise|
            ::Content::Exercise.new(strategy: entity_exercise)
          end
        end

        alias_method :string_tutor_uuid, :tutor_uuid
        def tutor_uuid
          ::Content::Uuid.new(string_tutor_uuid)
        end

        alias_method :string_uuid, :uuid
        def uuid
          ::Content::Uuid.new(string_uuid)
        end

      end
    end
  end
end
