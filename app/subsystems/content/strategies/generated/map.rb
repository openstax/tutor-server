module Content
  module Strategies
    module Generated
      class Map

        class << self
          def create(from_ecosystems:, to_ecosystem:)
            strategy = new(from_ecosystems: from_ecosystems, to_ecosystem: to_ecosystem)
            ::Content::Map.new(strategy: strategy)
          end

          def create!(from_ecosystems:, to_ecosystem:)
            create(from_ecosystems: from_ecosystems, to_ecosystem: to_ecosystem).tap do |map|
              raise(
                Content::MapInvalidError, "Cannot generate a valid ecosystem map from " +
                "[#{from_ecosystems.collect(&:title).join(', ')}] to #{to_ecosystem.title}"
              ) unless map.valid?
            end
          end

          alias_method :find, :create

          alias_method :find!, :create!
        end

        def initialize(from_ecosystems:, to_ecosystem:)
          @from_ecosystems = from_ecosystems
          @to_ecosystem = to_ecosystem

          @page_id_to_page_map = to_ecosystem.pages.each_with_object({}) do |page, hash|
            hash[page.id] = page
          end
          @exercise_id_to_page_map = {}
        end

        def map_exercises_to_pages(exercises:)
          exercise_ids = exercises.collect(&:id)
          mapped_exercises = @exercise_id_to_page_map.slice(*exercise_ids)
          unmapped_exercise_ids = exercise_ids - mapped_exercises.keys

          return mapped_exercises if unmapped_exercise_ids.empty?

          unmapped_content_exercises = Content::Models::Exercise
            .joins(tags: :same_value_tags)
            .where(id: unmapped_exercise_ids,
                   tags: {
                     content_ecosystem_id: @from_ecosystems.collect(&:id),
                     tag_type: Content::Models::Tag::OBJECTIVE_TAG_TYPES,
                     same_value_tags: {
                       content_ecosystem_id: @to_ecosystem.id,
                       tag_type: Content::Models::Tag::OBJECTIVE_TAG_TYPES,
                     }
                   })
            .preload(tags: {same_value_tags: :pages})

          @exercise_id_to_page_map = unmapped_content_exercises
            .each_with_object(@exercise_id_to_page_map) do |content_exercise, hash|

            objective_tags = content_exercise.tags.select{ |tag| tag.lo? || tag.aplo? }
            tags_across_ecosystems = objective_tags.collect(&:same_value_tags).flatten
                                                   .select{ |tag| tag.lo? || tag.aplo? }
            content_pages = tags_across_ecosystems.collect{ |tag| tag.pages }.flatten.uniq
            ecosystem_pages = content_pages.collect{ |cp| @page_id_to_page_map[cp.id] }.compact

            # We only allow each exercise to map to 1 page
            hash[content_exercise.id] = ecosystem_pages.size == 1 ? ecosystem_pages.first : nil

          end

          mapped_exercises.merge(@exercise_id_to_page_map.slice(*unmapped_exercise_ids))
        end

        def valid?
          return @valid unless @valid.nil?

          all_exercises = @from_ecosystems.flat_map(&:exercises)

          all_map = map_exercises_to_pages(exercises: all_exercises)

          # The hash returned has all exercises given as keys
          # All values in the hash are ::Content::Page's from the to_ecosystem
          @valid = Set.new(all_map.keys) == Set.new(all_exercises.collect(&:id)) && \
                   Set.new(all_map.values).subset?(Set.new(@to_ecosystem.pages))
        end

      end
    end
  end
end
