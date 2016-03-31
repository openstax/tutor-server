module Content
  module Strategies
    module Generated
      class Manifest < Hashie::Mash

        class Book < Hashie::Mash

          class ReadingFeatures < Hashie::Mash
          end

          def to_h
            super.merge('reading_features' => reading_features._strategy.to_h)
          end

          def reading_features
            strategy = ::Content::Strategies::Generated::Manifest::Book::ReadingFeatures.new(super)
            ::Content::Manifest::Book::ReadingFeatures.new(strategy: strategy)
          end

          def valid?
            cnx_id.present? && (exercise_ids || []).all?{ |ex_id| ex_id.is_a? String }
          end

          def update_version!
            self.cnx_id = cnx_id.split('@').first
            ::Content::Manifest::Book.new(strategy: self)
          end

          def unlock_exercises!
            delete(:exercise_ids)
            ::Content::Manifest::Book.new(strategy: self)
          end

        end

        def self.from_yaml(yaml)
          new(YAML.load(yaml))
        end

        def to_h
          super.merge('books' => books.map{ |book| book._strategy.to_h })
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
