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
            map = create(from_ecosystems: from_ecosystems, to_ecosystem: to_ecosystem)
            raise ::Content::StrategyError unless map.valid?
            map
          end

          alias_method :find, :create

          alias_method :find!, :create!
        end

        def initialize(from_ecosystems:, to_ecosystem:)
          @from_ecosystems = from_ecosystems
          @to_ecosystem = to_ecosystem
        end

        def map_exercises_to_pages(exercises:)
          all_pages = @to_ecosystem.pages
          page_map = all_pages.each_with_object({}) do |page, hash|
            hash[page.id] = page
          end

          exercise_ids = exercises.collect(&:id)

          content_exercises = Content::Models::Exercise
                                .joins(tags: :same_value_tags)
                                .eager_load(tags: {same_value_tags: :pages})
                                .where(id: exercise_ids,
                                       tags: {
                                         content_ecosystem_id: @from_ecosystems.collect(&:id),
                                         tag_type: Content::Models::Tag::OBJECTIVE_TAG_TYPES,
                                         same_value_tags: {
                                           content_ecosystem_id: @to_ecosystem.id,
                                           tag_type: Content::Models::Tag::OBJECTIVE_TAG_TYPES,
                                         }
                                       })
          exercise_map = content_exercises.each_with_object({}) do |content_exercise, hash|
            objective_tags = content_exercise.tags.select{ |tag| tag.lo? || tag.aplo? }
            tags_across_ecosystems = objective_tags.collect(&:same_value_tags).flatten
                                                   .select{ |tag| tag.lo? || tag.aplo? }
            content_pages = tags_across_ecosystems.collect{ |tag| tag.pages }.flatten.uniq
            ecosystem_pages = content_pages.collect{ |cp| page_map[cp.id] }.compact

            # We only allow each exercise to map to 1 page
            hash[content_exercise.id] = ecosystem_pages.size == 1 ? ecosystem_pages.first : nil
          end

          exercise_ids.collect{ |exercise_id| exercise_map[exercise_id] }
        end

        def valid?
          return @valid unless @valid.nil?

          all_exercises = @from_ecosystems.collect{ |es| es.exercises }.flatten

          all_map = map_exercises_to_pages(exercises: all_exercises)

          # The array returned has the same size as the input array
          # All elements in the array are ::Content::Page's from the to_ecosystem
          @valid = all_map.size == all_exercises.size && \
                   Set.new(all_map).subset?(Set.new(@to_ecosystem.pages))
        end

      end
    end
  end
end
