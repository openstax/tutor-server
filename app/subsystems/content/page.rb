module Content
  class Page

    include Wrapper

    def id
      verify_and_return @strategy.id, klass: Integer
    end

    def url
      verify_and_return @strategy.url, klass: String
    end

    def uuid
      verify_and_return @strategy.uuid, klass: String
    end

    def version
      verify_and_return @strategy.version, klass: String
    end

    def cnx_id
      verify_and_return @strategy.cnx_id, klass: String
    end

    def title
      verify_and_return @strategy.title, klass: String
    end

    def content
      verify_and_return @strategy.content, klass: String
    end

    def chapter
      verify_and_return @strategy.chapter, klass: ::Content::Chapter
    end

    def reading_dynamic_pool
      verify_and_return @strategy.reading_dynamic_pool, klass: ::Content::Pool
    end

    def reading_try_another_pool
      verify_and_return @strategy.reading_try_another_pool, klass: ::Content::Pool
    end

    def homework_core_pool
      verify_and_return @strategy.homework_core_pool, klass: ::Content::Pool
    end

    def homework_dynamic_pool
      verify_and_return @strategy.homework_dynamic_pool, klass: ::Content::Pool
    end

    def practice_widget_pool
      verify_and_return @strategy.practice_widget_pool, klass: ::Content::Pool
    end

    def pool_ids
      [reading_dynamic_pool,
       reading_try_another_pool,
       homework_core_pool,
       homework_dynamic_pool,
       practice_widget_pool].compact.collect(&:uuid)
    end

    def exercises
      verify_and_return @strategy.exercises, klass: ::Content::Exercise
    end

    def book_location
      verify_and_return @strategy.book_location, klass: Integer
    end

    def is_intro?
      !!@strategy.is_intro?
    end

    def fragments
      @strategy.fragments
    end

    def tags
      verify_and_return @strategy.tags, klass: ::Content::Tag
    end

    def los
      verify_and_return @strategy.los, klass: ::Content::Tag
    end

    def aplos
      verify_and_return @strategy.aplos, klass: ::Content::Tag
    end

    def related_content(title: nil, book_location: nil)
      related_content = @strategy.related_content(title: title, book_location: book_location)
      verify_and_return related_content, klass: Hash
    end

  end
end
