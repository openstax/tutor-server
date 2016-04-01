module Content
  module Strategies
    module Generated
      class Manifest < Hashie::Mash

        def self.from_yaml(yaml)
          new(YAML.load(yaml))
        end

        def to_h
          super.merge('books' => books.map(&:to_h))
        end

        def to_yaml
          to_h.to_yaml
        end

        def books
          super.to_a.map do |book_hash|
            strategy = ::Content::Strategies::Generated::Manifest::Book.new(book_hash)
            ::Content::Manifest::Book.new(strategy: strategy)
          end
        end

        def valid?
          title.present? && books.present? && books.all?{ |book| book.valid? }
        end

        def update_books!
          books.each(&:update_version!)
          ::Content::Manifest.new(strategy: self)
        end

        def unlock_exercises!
          books.each(&:unlock_exercises!)
          ::Content::Manifest.new(strategy: self)
        end

      end
    end
  end
end
