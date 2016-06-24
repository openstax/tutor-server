class Content::Models::Map < Tutor::SubSystems::BaseModel
  serialize :exercise_id_to_page_id_map, JSON
  serialize :page_id_to_page_id_map, JSON
  serialize :page_id_to_pool_type_exercise_ids_map, JSON

  belongs_to :from_ecosystem, class_name: '::Content::Models::Ecosystem', inverse_of: :to_maps
  belongs_to :to_ecosystem, class_name: '::Content::Models::Ecosystem', inverse_of: :from_maps

  validates :from_ecosystem, :to_ecosystem, presence: true
  validates :to_ecosystem, uniqueness: { scope: :content_from_ecosystem_id }

  after_initialize :enforce_map_types

  before_save :create_exercise_id_to_page_id_map, :create_page_id_to_page_id_map,
              :create_page_id_to_pool_type_exercise_ids_map, :validate_maps

  def create_exercise_id_to_page_id_map
    return unless exercise_id_to_page_id_map.blank?

    # Special case: from_ecosystem == to_ecosystem
    # Mapping succeeds even if the exercise has no tags
    if from_ecosystem == to_ecosystem
      to_ecosystem.exercises.each do |exercise|
        exercise_id_to_page_id_map[exercise.id.to_s] = exercise.content_page_id
      end

      return exercise_id_to_page_id_map
    end

    exercise_id_to_pages_map = Content::Models::Page
      .joins(tags: {same_value_tags: :exercises})
      .where(tags: {
               content_ecosystem_id: to_ecosystem.id,
               tag_type: mapping_tag_types,
               same_value_tags: {
                 content_ecosystem_id: from_ecosystem.id,
                 tag_type: mapping_tag_types
               }
             })
      .uniq
      .select{[Content::Models::Page.arel_table[:id],
               Content::Models::Page.arel_table[:book_location],
               tags.same_value_tags.exercises.id.as(:from_exercise_id)]}
      .group_by(&:from_exercise_id)

    # Each exercise maps to the highest numbered page that shares a mapping tag with it
    exercise_id_to_pages_map.each do |exercise_id, pages|
      exercise_id_to_page_id_map[exercise_id.to_s] = pages.max_by(&:book_location).id
    end

    exercise_id_to_page_id_map
  end

  def create_page_id_to_page_id_map
    return unless page_id_to_page_id_map.blank?

    # Special case: from_ecosystem == to_ecosystem
    # Mapping succeeds even if the page has no tags
    if from_ecosystem == to_ecosystem
      to_ecosystem.pages.each{ |page| page_id_to_page_id_map[page.id.to_s] = page.id }

      return page_id_to_page_id_map
    end

    page_id_to_pages_map = Content::Models::Page
      .joins(tags: {same_value_tags: :pages})
      .where(tags: {
               content_ecosystem_id: to_ecosystem.id,
               tag_type: mapping_tag_types,
               same_value_tags: {
                 content_ecosystem_id: from_ecosystem.id,
                 tag_type: mapping_tag_types
               }
             })
      .uniq
      .select{[Content::Models::Page.arel_table[:id],
               tags.same_value_tags.pages.id.as(:from_page_id)]}
      .group_by(&:from_page_id)

    # It could happen in theory that a page maps to 2 or more pages,
    # but for now we don't handle that case
    # since it's hard to figure out what to do for the dashboard/scores
    page_id_to_pages_map.each do |page_id, pages|
      page_id_to_page_id_map[page_id.to_s] = pages.size == 1 ? pages.first.id : nil
    end

    page_id_to_page_id_map
  end

  def create_page_id_to_pool_type_exercise_ids_map
    return unless page_id_to_pool_type_exercise_ids_map.blank?

    create_page_id_to_page_id_map

    pool_types = Content::Models::Pool.pool_types.keys
    pool_association_to_pool_type_map = pool_types.index_by do |pool_type|
      "#{pool_type}_pool".to_sym
    end
    pool_associations = pool_association_to_pool_type_map.keys

    to_pages_map = to_ecosystem.pages.preload(pool_associations).index_by(&:id)

    page_id_to_page_id_map.each do |from_page_id, to_page_id|
      page_id_to_pool_type_exercise_ids_map[from_page_id] = {}

      to_page = to_pages_map[to_page_id]

      pool_association_to_pool_type_map.each do |pool_association, pool_type|
        pool = to_page.try(pool_association)
        page_id_to_pool_type_exercise_ids_map[from_page_id][pool_type] = \
          pool.try :content_exercise_ids
      end
    end

    page_id_to_pool_type_exercise_ids_map
  end

  def validate_maps
    return unless is_valid.nil? || validity_error_messages.nil?

    self.is_valid = true
    self.validity_error_messages = []

    all_exercises_are_mapped
    exercises_map_to_pages
    pages_map_to_pages
    pages_map_to_exercises
  end

  protected

  def enforce_map_types
    self.exercise_id_to_page_id_map = exercise_id_to_page_id_map.to_h \
      unless exercise_id_to_page_id_map.is_a?(Hash)
    self.page_id_to_page_id_map = page_id_to_page_id_map.to_h \
      unless page_id_to_page_id_map.is_a?(Hash)
    self.page_id_to_pool_type_exercise_ids_map = page_id_to_pool_type_exercise_ids_map.to_h \
        unless page_id_to_pool_type_exercise_ids_map.is_a?(Hash)
  end

  def mapping_tag_types
    @mapping_tag_types ||= Content::Models::Tag::MAPPING_TAG_TYPES.map do |type|
      Content::Models::Tag.tag_types[type]
    end
  end

  # Every exercise id in the from_ecosystem is a string key in the exercise_id_to_page_id_map
  # This check may fail if an exercise fails to map to any page in the new ecosystem
  def all_exercises_are_mapped
    from_exercises                      = from_ecosystem.exercises
    from_exercise_ids_set               = Set.new from_exercises.map{ |ex| ex.id.to_s }
    exercise_id_to_page_id_map_keys_set = Set.new exercise_id_to_page_id_map.keys

    return true if from_exercise_ids_set == exercise_id_to_page_id_map_keys_set

    unmapped_ex_uids = from_exercises.reject do |ex|
      exercise_id_to_page_id_map_keys_set.include? ex.id.to_s
    end.map(&:uid)

    validity_error_messages << "Unmapped exercise uids: [#{unmapped_ex_uids.to_a.join(', ')}]"
    self.is_valid = false
  end

  # Every value in the exercise_id_to_page_id_map is the id of a page in the to_ecosystem (no nils)
  # This check may fail if an exercise fails to map to any page in the new ecosystem
  def exercises_map_to_pages
    exercise_id_to_page_id_map_values_set = Set.new exercise_id_to_page_id_map.values
    to_page_ids_set                       = Set.new to_ecosystem.pages.map(&:id)

    return true if exercise_id_to_page_id_map_values_set.subset?(to_page_ids_set)

    from_exercises_by_id = from_ecosystem.exercises.index_by{ |ex| ex.id.to_s }
    to_pages_by_id = to_ecosystem.pages.index_by(&:id)

    mismapped_hash = exercise_id_to_page_id_map.reject do |ex_id, pg_id|
      to_page_ids_set.include? pg_id
    end

    error_messages = mismapped_hash.map do |ex_id, pg_id|
      ex_uid = from_exercises_by_id[ex_id].try(:uid) || 'nil'
      title  = to_pages_by_id[pg_id].try(:title) || 'nil'
      "#{ex_uid} => \"#{title}\""
    end

    validity_error_messages << "Mismapped exercises: [#{error_messages.join(', ')}]"
    self.is_valid = false
  end

  # Every value in the page_id_to_page_id_map is the id of a page in the to_ecosystem (no nils)
  # This is more of an internal check and should never fail
  def pages_map_to_pages
    page_id_to_page_id_map_values_set = Set.new page_id_to_page_id_map.values
    to_page_ids_set                   = Set.new to_ecosystem.pages.map(&:id)

    return true if page_id_to_page_id_map_values_set.subset?(to_page_ids_set)

    from_pages_by_id = from_ecosystem.pages.index_by{ |ex| ex.id.to_s }
    to_pages_by_id = from_ecosystem.pages.index_by(&:id)

    mismapped_hash = page_id_to_page_id_map.reject do |from_pg_id, to_pg_id|
      to_page_ids_set.include? to_pg_id
    end

    error_messages = mismapped_hash.map do |from_pg_id, to_pg_id|
      from_title = from_pages_by_id[from_pg_id].try(:title) || 'nil'
      to_title  = to_pages_by_id[to_pg_id].try(:title) || 'nil'
      "\"#{from_title}\" => \"#{to_title}\""
    end

    validity_error_messages << "Mismapped pages: [#{error_messages.join(', ')}]"
    self.is_valid = false
  end

  # Every value in the page_id_to_pool_type_exercise_ids_map is a hash that maps to
  # an array of ids of exercises in the to_ecosystem (can be empty, no nils)
  # This is more of an internal check and should never fail
  def pages_map_to_exercises
    pool_type_exercise_ids_maps            = page_id_to_pool_type_exercise_ids_map.values
    pool_type_exercise_ids_maps_values_set = Set.new pool_type_exercise_ids_maps.map(&:values)
                                                                                .flatten
    to_exercise_ids_set                    = Set.new to_ecosystem.exercises.map(&:id)

    return true if pool_type_exercise_ids_maps_values_set.subset?(to_exercise_ids_set)

    pool_types = Content::Models::Pool.pool_types.keys.map(&:to_sym)
    from_pages_by_id = from_ecosystem.pages.index_by{ |ex| ex.id.to_s }
    to_exercises_by_id = from_ecosystem.exercises.index_by(&:id)

    error_messages = []
    page_id_to_pool_type_exercise_ids_map.each do |pg_id, pool_type_exercise_ids_map|
      pool_types.each do |pool_type|
        exercise_ids = pool_type_exercise_ids_map[pool_type]

        next if exercise_ids.is_a?(Array) &&
                exercise_ids.all?{ |ex_id| to_exercise_ids_set.include? ex_id }

        title = from_pages_by_id[pg_id].try(:title) || 'nil'
        ex_uids = exercise_ids.is_a?(Array) ? "[#{exercise_ids.map do |ex_id|
          to_exercises_by_id[ex_id].try(:uid) || 'nil'
        end}]" : exercise_ids.inspect
        error_messages << "\"#{title}\" => { #{pool_type}: #{ex_uids} }"
      end
    end

    validity_error_messages << "Mismapped pages: [#{error_messages.join(', ')}]"
    self.is_valid = false
  end
end
