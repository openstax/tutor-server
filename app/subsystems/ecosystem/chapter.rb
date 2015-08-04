module Ecosystem
  class Chapter < Wrapper

    def title
      title = @strategy.title

      raise_collection_class_error(
        collection: title,
        klass:      String,
        error:      ::Ecosystem::StrategyError
      )

      title
    end

    def pages
      pages = @strategy.pages

      raise_collection_class_error(
        collection: pages,
        klass:      ::Ecosystem::Page,
        error:      ::Ecosystem::StrategyError
      )

      pages
    end

    def chapter_section
      chapter_section = @strategy.chapter_section

      raise_collection_class_error(
        collection: chapter_section,
        klass:      Integer,
        error:      ::Ecosystem::StrategyError
      )

      chapter_section
    end

  end
end
