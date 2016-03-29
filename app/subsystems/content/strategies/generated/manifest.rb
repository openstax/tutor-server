module Content
  module Strategies
    module Generated
      class Manifest

        def self.from_yaml(yaml)
          new(hash: YAML.load(yaml))
        end

        def to_yaml
          @hash.to_yaml
        end

        def initialize(hash:)
          @hash = HashWithIndifferentAccess.new(hash).slice(
            :ecosystem_title, :book_uuids, :book_versions, :exercise_numbers, :exercise_versions
          )
        end

        def valid?
          ecosystem_title.present? && \
          book_uuids.present? && book_versions.present? && \
          exercise_numbers.present? && exercise_versions.present? && \
          book_uuids.size == book_versions.size && \
          exercise_numbers.size == exercise_versions.size && \
          book_uuids.all?{ |uuid| uuid.is_a?(::Content::Uuid) && uuid.valid? } && \
          book_versions.all?{ |version| version.is_a? String } && \
          exercise_numbers.all?{ |number| number.is_a? Integer } && \
          exercise_versions.all?{ |version| version.is_a? Integer }
        end

        def ecosystem_title
          @hash[:ecosystem_title].to_s
        end

        def book_uuids
          @hash[:book_uuids].to_a
        end

        def book_versions
          @hash[:book_versions].to_a
        end

        def book_cnx_ids
          versions = book_versions
          book_uuids.each_with_index.collect{ |uuid, idx| "#{uuid}@#{versions[idx]}" }
        end

        def exercise_numbers
          @hash[:exercise_numbers].to_a
        end

        def exercise_versions
          @hash[:exercise_versions].to_a
        end

        def exercise_uids
          versions = exercise_versions
          exercise_numbers.each_with_index.collect{ |number, idx| "#{number}@#{versions[idx]}" }
        end

      end
    end
  end
end
