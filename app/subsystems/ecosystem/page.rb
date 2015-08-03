module Ecosystem
  class Page < Wrapper

    def self.find(*args, strategy_class: ::Ecosystem::Strategies::Direct::Page)
      strategy_class.find(*args).collect do |strategy|
        new(strategy: strategy)
      end
    end

    def url
      url = @strategy.url

      raise_collection_class_error(
        collection: url,
        klass:      String,
        error:      ::Ecosystem::StrategyError
      )

      url
    end

    def title
      title = @strategy.title

      raise_collection_class_error(
        collection: title,
        klass:      String,
        error:      ::Ecosystem::StrategyError
      )

      title
    end

    def content
      content = @strategy.content

      raise_collection_class_error(
        collection: content,
        klass:      String,
        error:      ::Ecosystem::StrategyError
      )

      content
    end

    def chapter
      chapter = @strategy.chapter

      raise_collection_class_error(
        collection: chapter,
        klass:      ::Ecosystem::Chapter,
        error:      ::Ecosystem::StrategyError
      )

      chapter
    end

    def chapter_section
      chapter_section = @strategy.chapter_section

      raise_collection_class_error(
        collection: chapter_section,
        klass:      Array,
        error:      ::Ecosystem::StrategyError
      )

      chapter_section
    end

    def is_intro?
      !!@strategy.is_intro?
    end

    def tags
      tags = @strategy.tags

      raise_collection_class_error(
        collection: tags,
        klass:      String,
        error:      ::Ecosystem::StrategyError
      )

      tags
    end

    def los
      los = @strategy.los

      raise_collection_class_error(
        collection: los,
        klass:      String,
        error:      ::Ecosystem::StrategyError
      )

      los
    end

    def aplos
      aplos = @strategy.aplos

      raise_collection_class_error(
        collection: aplos,
        klass:      String,
        error:      ::Ecosystem::StrategyError
      )

      aplos
    end

  end
end
