module Ecosystem
  class Page

    include Wrapper

    def id
      verify_and_return @strategy.id, klass: Integer
    end

    def url
      verify_and_return @strategy.url, klass: String
    end

    def title
      verify_and_return @strategy.title, klass: String
    end

    def content
      verify_and_return @strategy.content, klass: String
    end

    def chapter
      verify_and_return @strategy.chapter, klass: ::Ecosystem::Chapter
    end

    def chapter_section
      verify_and_return @strategy.chapter_section, klass: Integer
    end

    def is_intro?
      !!@strategy.is_intro?
    end

    def fragments
      @strategy.fragments
    end

    def tags
      verify_and_return @strategy.tags, klass: String
    end

    def los
      verify_and_return @strategy.los, klass: String
    end

    def aplos
      verify_and_return @strategy.aplos, klass: String
    end

    def related_content(title: nil, chapter_section: nil)
      related_content = @strategy.related_content(title: title, chapter_section: chapter_section)
      verify_and_return related_content, klass: Hash
    end

  end
end
