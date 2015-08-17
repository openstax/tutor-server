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
            strategy = new(from_ecosystems: from_ecosystems, to_ecosystem: to_ecosystem)
            map = ::Content::Map.new(strategy: strategy)
            raise StrategyError unless map.valid?
            map
          end

          def find(from_ecosystems:, to_ecosystem:)
            create(from_ecosystems: from_ecosystems, to_ecosystem: to_ecosystem)
          end

          def find!(from_ecosystems:, to_ecosystem:)
            create!(from_ecosystems: from_ecosystems, to_ecosystem: to_ecosystem)
          end
        end

        def initialize(from_ecosystems:, to_ecosystem:)
          @from_ecosystems = from_ecosystems
          @to_ecosystem = to_ecosystem
        end

        def group_exercises_by_pages(exercises:)
          all_pages = @to_ecosystem.pages
          page_map = all_pages.each_with_object({}) do |page, hash|
            hash[page.id] = page
          end

          exercise_map = exercises.each_with_object({}) do |exercise, hash|
            hash[exercise.id] = exercise
          end
          exercise_ids = exercise_map.keys

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
                                .to_a
                                

          content_exercises.each_with_object({}) do |content_exercise, hash|
            objective_tags = content_exercise.tags.select{ |tag| tag.lo? || tag.aplo? }
            tags_across_ecosystems = objective_tags.collect(&:same_value_tags).flatten
                                                   .select{ |tag| tag.lo? || tag.aplo? }
            content_pages = tags_across_ecosystems.collect{ |tag| tag.pages }.flatten.uniq

            ecosystem_exercise = exercise_map[content_exercise.id]
            ecosystem_pages = content_pages.collect{ |cp| page_map[cp.id] }.compact
            ecosystem_pages.each do |ecosystem_page|
              hash[ecosystem_page] ||= []
              hash[ecosystem_page] << ecosystem_exercise
            end
          end
        end

        def valid?
          return @valid unless @valid.nil?

          all_exercises = @from_ecosystems.collect{ |es| es.exercises }.flatten
          all_exercises_set = Set.new all_exercises
          all_pages_set = Set.new @to_ecosystem.pages

          all_map = group_exercises_by_pages(exercises: all_exercises)
          all_keys_set = Set.new all_map.keys
          all_values = all_map.values.flatten
          all_values_set = Set.new all_values

          # All pages returned belong to the to_ecosystem
          # All exercises given in the set are included (no orphans)
          # No exercise is in 2 different pages
          @valid = all_keys_set.subset?(all_pages_set) && \
                   all_values_set == all_exercises_set && \
                   all_values.size == all_values_set.size
        end

      end
    end
  end
end
