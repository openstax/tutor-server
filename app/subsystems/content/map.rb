module Content
  class Map
    attr_accessor :is_valid, :validity_error_message
    attr_reader :to_ecosystem

    class << self
      def find_or_create_by(from_ecosystems:, to_ecosystem:)
        new(from_ecosystems: from_ecosystems, to_ecosystem: to_ecosystem)
      end

      def find_or_create_by!(from_ecosystems:, to_ecosystem:)
        find_or_create_by(from_ecosystems: from_ecosystems, to_ecosystem: to_ecosystem).tap do |map|
          raise(::Content::MapInvalidError, map.validity_error_message) unless map.is_valid
        end
      end
    end

    def initialize(from_ecosystems:, to_ecosystem:)
      @to_ecosystem = to_ecosystem
      maps = find_or_create_maps(from_ecosystems: from_ecosystems, to_ecosystem: to_ecosystem)
      merge_maps(maps: maps)
    end

    # Returns a hash that maps the given exercise_ids to a page_id in the to_ecosystem
    # Unmapped exercise_ids map to nil
    def map_exercise_ids_to_page_ids(exercise_ids:)
      {}.tap do |result|
        exercise_ids.each do |exercise_id|
          result[exercise_id] = @exercise_id_to_page_id_map[exercise_id.to_s]
        end
      end
    end

    # Returns a hash that maps the given page_ids to a page_id in the to_ecosystem
    # Unmapped page_ids map to nil
    def map_page_ids(page_ids:)
      {}.tap do |result|
        page_ids.each { |page_id| result[page_id] = @page_id_to_page_id_map[page_id.to_s] }
      end
    end

    # Returns a hash that maps the given Content::Pages
    # to Content::Exercises in the to_ecosystem that are in a Content::Pool of the given type
    def map_page_ids_to_exercise_ids(page_ids:, pool_type: :all)
      {}.tap do |result|
        page_ids.each do |page_id|
          result[page_id] =
            @page_id_to_pool_type_exercise_ids_map[page_id.to_s]&.[](pool_type.to_s) || []
        end
      end
    end

    protected

    def find_or_create_maps(from_ecosystems:, to_ecosystem:)
      existing_maps = Content::Models::Map.where(
        content_from_ecosystem_id: from_ecosystems.map(&:id),
        content_to_ecosystem_id: to_ecosystem.id
      )

      existing_from_ecosystems_ids = existing_maps.map(&:content_from_ecosystem_id)

      missing_from_ecosystems = from_ecosystems.reject do |ecosystem|
        existing_from_ecosystems_ids.include?(ecosystem.id)
      end

      new_maps = upsert_maps(
        from_ecosystems: missing_from_ecosystems, to_ecosystem: to_ecosystem
      )

      existing_maps + new_maps
    end

    def upsert_maps(from_ecosystems:, to_ecosystem:)
      from_ecosystems.uniq.map do |from_ecosystem|
        Content::Models::Map.new(
          from_ecosystem: from_ecosystem, to_ecosystem: to_ecosystem
        ).tap { |map| map.before_save_callbacks }
      end.tap do |new_maps|
        Content::Models::Map.import new_maps, validate: false, on_duplicate_key_ignore: {
          conflict_target: [ :content_from_ecosystem_id, :content_to_ecosystem_id ]
        }
      end
    end

    def merge_maps(maps:)
      @page_id_to_page_id_map = maps.map(&:page_id_to_page_id_map).reduce({}, :merge)
      @exercise_id_to_page_id_map = maps.map(&:exercise_id_to_page_id_map).reduce({}, :merge)
      @page_id_to_pool_type_exercise_ids_map = maps.map(&:page_id_to_pool_type_exercise_ids_map)
                                                   .reduce({}, :merge)
      merge_map_validities(maps: maps)
    end

    def merge_map_validities(maps:)
      invalid_maps = maps.reject(&:is_valid)

      @is_valid = invalid_maps.none?

      @validity_error_message = invalid_maps.map do |ecosystem_map|
        "Invalid mapping: #{ecosystem_map.from_ecosystem.title} => #{
          ecosystem_map.to_ecosystem.title}. Errors: [#{
          ecosystem_map.validity_error_messages.join(', ')}]"
      end.join('; ')
    end
  end
end
