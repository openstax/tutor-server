module Content
  module Strategies
    module Generated
      class Manifest

        class Book

          class ReadingFeatures

            def initialize(hash:)
              @hash = hash.slice('reading_split_css', 'video_split_css', 'interactive_split_css',
                                 'required_exercise_css', 'optional_exercise_css', 'discard_css')
            end

            def reading_split_css
              @hash['reading_split_css']
            end

            def video_split_css
              @hash['video_split_css']
            end

            def interactive_split_css
              @hash['interactive_split_css']
            end

            def required_exercise_css
              @hash['required_exercise_css']
            end

            def optional_exercise_css
              @hash['optional_exercise_css']
            end

            def discard_css
              @hash['discard_css']
            end

          end

          def initialize(hash:)
            @hash = hash.slice('archive_url', 'cnx_id', 'reading_features', 'exercise_ids')
          end

          def archive_url
            @hash['archive_url']
          end

          def cnx_id
            @hash['cnx_id']
          end

          def reading_features
            strategy = ::Content::Strategies::Generated::Manifest::Book::ReadingFeatures.new(
              hash: @hash['reading_features']
            )
            ::Content::Manifest::Book::ReadingFeatures.new(strategy: strategy)
          end

          def exercise_ids
            @hash['exercise_ids']
          end

          def valid?
            cnx_id.present? && (exercise_ids || []).all?{ |ex_id| ex_id.is_a? String }
          end

          def update_version!
            @hash['cnx_id'] = cnx_id.split('@').first
            ::Content::Manifest::Book.new(strategy: self)
          end

          def unlock_exercises!
            @hash.delete('exercise_ids')
            ::Content::Manifest::Book.new(strategy: self)
          end

        end

        def self.from_yaml(yaml)
          new(hash: YAML.load(yaml))
        end

        def to_yaml
          @hash.to_yaml
        end

        def initialize(hash:)
          @hash = hash.deep_stringify_keys.slice('title', 'books')
        end

        def title
          @hash['title']
        end

        def books
          @hash['books'].to_a.map do |book_hash|
            strategy = ::Content::Strategies::Generated::Manifest::Book.new(hash: book_hash)
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
