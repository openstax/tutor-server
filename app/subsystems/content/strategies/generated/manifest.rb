module Content
  module Strategies
    module Generated
      class Manifest

        def self.from_yaml(yaml)
          new(hash: YAML.load(yaml))
        end

        def to_yaml
          @hash.to_h.to_yaml
        end

        def initialize(hash:)
          @hash = HashWithIndifferentAccess.new(hash).slice(
            :ecosystem_title, :archive_url, :book_ids, :exercise_ids
          )
        end

        def ecosystem_title
          @hash[:ecosystem_title]
        end

        def archive_url
          @hash[:archive_url]
        end

        def book_ids
          @hash[:book_ids].to_a
        end

        def exercise_ids
          @hash[:exercise_ids]
        end

        def valid?
          ecosystem_title.present? && \
          book_ids.present? && book_ids.first.present? && \
          book_ids.all?{ |id| id.is_a? String } && \
          (exercise_ids.nil? || exercise_ids.all?{ |id| id.is_a? String })
        end

        def update_book!
          @hash[:book_ids] = @hash[:book_ids].map{ |book_id| book_id.split('@').first }
          self
        end

        def unlock_exercises!
          @hash.delete(:exercise_ids)
          self
        end

      end
    end
  end
end
