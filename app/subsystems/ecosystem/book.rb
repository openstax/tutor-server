module Ecosystem
  class Book < Wrapper

    def title
      title = @strategy.title

      raise_collection_class_error(
        collection: title,
        klass:      String,
        error:      ::Ecosystem::StrategyError
      )

      title
    end

    def chapters
      chapters = @strategy.chapters

      raise_collection_class_error(
        collection: chapters,
        klass:      ::Ecosystem::Chapter,
        error:      ::Ecosystem::StrategyError
      )

      chapters
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

  end
end
