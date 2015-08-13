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

          content_exercises = Content::Models::Exercise.where(id: exercise_ids)
                                                       .eager_load(tags: :pages)
                                                       .to_a

          content_pages_arrays = content_exercises.collect do |ce|
            objective_tags = ce.tags.select{ |tag| tag.lo? || tag.aplo? }
            objective_tags.collect{ |tag| tag.pages }.flatten.compact.uniq
          end

          content_pages_arrays.each_with_index.each_with_object({}) do |(content_pages, idx), hash|
            exercise = exercises.find{ |ex| ex.id == ce.id }
            pages = content_pages.collect{ |cp| all_pages.find{ |pg| pg.id == cp.id } }.compact
            pages.each do |page|
              hash[page] ||= []
              hash[page] << exercise
            end
          end
        end

        def valid?
          return @valid unless @valid.nil?

          all_exercises_set = Set.new @from_ecosystems.collect{ |es| es.exercises }.flatten
          all_pages_set = Set.new @to_ecosystem.pages

          all_map = map_exercises_to_pages(exercises: all_exercises)
          all_keys_set = Set.new all_map.keys
          all_values = all_map.values.flatten
          all_values_set = Set.new all_values

          @valid = all_keys_set.subset?(all_pages_set) && \ # All pages belong to the to_ecosystem
                   all_values_set == all_exercises_set && \ # All exercises in the set are included
                   all_values.size == all_values_set.size   # No exercise is in 2 different pages
        end

      end
    end
  end
end
