module Ecosystem
  class Exercise < Wrapper

    def self.find(*args, strategy_class: ::Ecosystem::Strategies::Direct::Exercise)
      [strategy_class.find(*args)].flatten.collect do |strategy|
        new(strategy: strategy)
      end
    end

    def self.find_by(*args, strategy_class: ::Ecosystem::Strategies::Direct::Exercise)
      [strategy_class.find_by(*args)].flatten.collect do |strategy|
        new(strategy: strategy)
      end
    end

    def uid
      uid = @strategy.uid

      raise_collection_class_error(
        collection: uid,
        klass:      String,
        error:      ::Ecosystem::StrategyError
      )

      uid
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

    def pages
      pages = @strategy.pages

      raise_collection_class_error(
        collection: pages,
        klass:      ::Ecosystem::Page,
        error:      ::Ecosystem::StrategyError
      )

      pages
    end

    def related_content
      related_content = @strategy.related_content

      raise_collection_class_error(
        collection: related_content,
        klass:      Hash,
        error:      ::Ecosystem::StrategyError
      )

      related_content
    end

  end
end
