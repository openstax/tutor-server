module Ecosystem
  module Strategies
    module Direct
      class Book < Entity

        wraps ::Content::Models::Book

        exposes :url, :uuid, :version, :title, :chapters, :pages

        alias_method :string_uuid, :uuid
        def uuid
          ::Ecosystem::Uuid.new(string_uuid)
        end

        alias_method :entity_chapters, :chapters
        def chapters
          entity_chapters.collect do |entity_chapter|
            ::Ecosystem::Chapter.new(strategy: entity_chapter)
          end
        end

        alias_method :entity_pages, :pages
        def pages
          entity_pages.collect do |entity_page|
            ::Ecosystem::Page.new(strategy: entity_page)
          end
        end

        def toc
          {
            url: url,
            uuid: uuid,
            version: version,
            title: title,
            chapters: entity_chapters.eager_load(:pages).collect{ |ch| ch.toc }
          }
        end

      end
    end
  end
end
