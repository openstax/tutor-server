class Content::Models::Map < Tutor::SubSystems::BaseModel
  belongs_to :from_ecosystem, class_name: '::Content::Models::Ecosystem', inverse_of: :to_maps
  belongs_to :to_ecosystem, class_name: '::Content::Models::Ecosystem', inverse_of: :from_maps

  validates :from_ecosystem, :to_ecosystem, presence: true
  validates :to_ecosystem, uniqueness: { scope: :content_from_ecosystem_id }

  before_validation :create_exercise_id_to_page_map, :create_page_id_to_page_map,
                    :create_page_id_to_pool_type_exercises_map, :validate_maps

  def create_exercise_id_to_page_map
    return unless exercise_id_to_page_map.nil?

    self.exercises_id_to_page_map = {}

    temp_exercise_id_to_pages_map = Content::Models::Page
      .joins(tags: {same_value_tags: :exercises})
      .where(tags: {
               content_ecosystem_id: to_ecosystem.id,
               tag_type: mapping_tag_types,
               same_value_tags: {
                 content_ecosystem_id: from_ecosystems_ids,
                 tag_type: mapping_tag_types
               }
             })
      .select{[Content::Models::Page.arel_table[Arel.star],
               tags.same_value_tags.exercises.id.as(:from_exercise_id)]}
      .to_a.group_by(&:from_exercise_id)

    # Each exercise maps to the highest numbered page that shares a mapping tag with it
    temp_exercise_id_to_pages_map.each do |exercise_id, pages|
      exercises_id_to_page_map[exercise_id] = pages.max_by(&:book_location)
    end

    exercises_id_to_page_map
  end

  def create_page_id_to_page_map
    return unless page_id_to_page_map.nil?

    self.page_id_to_page_map = {}

    temp_page_id_to_pages_map = Content::Models::Page
      .joins(tags: {same_value_tags: :pages})
      .where(tags: {
               content_ecosystem_id: to_ecosystem.id,
               tag_type: mapping_tag_types,
               same_value_tags: {
                 content_ecosystem_id: from_ecosystems_ids,
                 tag_type: mapping_tag_types
               }
             })
      .select{[Content::Models::Page.arel_table[Arel.star],
               tags.same_value_tags.pages.id.as(:from_page_id)]}
      .to_a.group_by(&:from_page_id)

    # It could happen in theory that a page maps to 2 or more pages,
    # but for now we don't handle that case
    # since it's hard to figure out what to do for the dashboard/scores
    temp_page_id_to_pages_map.each do |page_id, pages|
      page_id_to_page_map[page_id] = pages.size == 1 ? pages.first : nil
    end

    page_id_to_page_map
  end

  def create_page_id_to_pool_type_exercises_map
    return unless page_id_to_pool_type_exercises_map.nil?

    self.page_id_to_pool_type_exercises_map = {}

    create_page_id_to_page_map

    to_exercises_by_id = to_ecosystem.exercises.index_by(&:id)

    pool_association_to_pool_type_map = Content::Models::Pool.pool_types.keys
                                                             .map(&:to_sym).group_by do |pool_type|
      "#{pool_type}_pool".to_sym
    end

    page_id_to_page_map.each do |from_page_id, to_page|
      page_id_to_pool_type_exercises_map[from_page_id] = {}

      pool_association_to_pool_type_map.each do |pool_association, pool_type|
        pool = to_page.send(pool_association)
        exercises = pool.content_exercise_ids.map{ |ex_id| to_exercises_by_id[ex_id] }
        page_id_to_pool_type_exercises_map[from_page_id][pool_type] = exercises
      end
    end

    page_id_to_pool_type_exercises_map
  end

  def validate_maps
    return unless is_valid.nil? || validity_error_messages.nil?

    self.is_valid = true
    self.validity_error_messages = []

    all_exercises_are_mapped
    all_exercises_map_to_pages
    all_pages_are_mapped
    all_pages_map_to_pages
    all_pages_map_to_exercises
  end

  protected

  def mapping_tag_types
    @mapping_tag_types ||= Content::Models::Tag::MAPPING_TAG_TYPES.map do |type|
      Content::Models::Tag.tag_types[type]
    end
  end

  # Every exercise in the from_ecosystem is a key in the exercise_id_to_page_map
  def all_exercises_are_mapped
    all_exercises                    = from_ecosystem.exercises
    exercise_ids_set                 = Set.new all_exercises.map(&:id)
    exercise_id_to_page_map_keys_set = Set.new exercise_id_to_page_map.keys

    return true if exercise_ids_set == exercise_id_to_page_map_keys_set

    unmapped_ex_uids = all_exercises.reject do |ex|
      exercise_id_to_page_map_keys_set.include? ex.id
    end.map(&:uid)

    validity_error_messages << "Unmapped exercise uids: [#{unmapped_ex_uids.to_a.join(', ')}]"
    self.is_valid = false
  end

  # Every value in the exercise_id_to_page_map is a page in the to_ecosystem
  def all_exercises_map_to_pages
    exercise_id_to_page_map_values_set = Set.new exercise_id_to_page_map.values
    all_pages_set                      = Set.new to_ecosystem.pages

    return true if exercise_id_to_page_map_values_set.subset?(all_pages_set)

    exercises_by_id = from_ecosystem.exercises.index_by(&:id)
    mismapped_hash = exercise_id_to_page_map.reject{ |ex_id, page| all_pages_set.include? page }
    diag_info = mismapped_hash.map do |ex_id, page|
      ex_uid = exercises_by_id[ex_id].try(:uid) || 'nil'
      title  = page.try(:title) || 'nil'
      "#{ex_uid} => #{title}"
    end

    validity_error_messages << "Mismapped exercises (to pages): [#{diag_info.join(', ')}]"
    self.is_valid = false
  end

  # Every page in the from_ecosystem is a key in the page_id_to_page_map
  # and in the pool_type_page_id_to_exercises_map for all pools
  def all_pages_are_mapped
    all_pages                     = from_ecosystem.pages
    all_page_ids_set              = Set.new all_pages.map(&:id)
    page_id_to_page_map_keys_set = Set.new page_id_to_page_map.keys

    return true if all_page_ids_set == page_id_to_page_map_keys_set

    unmapped_pg_titles = all_pages.reject do |page|
      page_id_to_page_map_keys_set.include? page.id
    end.map(&:title)

    validity_error_messages << "Unmapped page titles: [#{unmapped_pg_titles.to_a.join(', ')}]"
    self.is_valid = false
  end

  # Every value in the page_id_to_page_map is a page in the to_ecosystem
  def all_pages_map_to_pages
    page_id_to_page_map_values_set = Set.new page_id_to_page_map.values
    all_pages_set                   = Set.new to_ecosystem.pages

    return true if page_id_to_page_map_values_set.subset?(all_pages_set)

    pages_by_id = from_ecosystem.pages.index_by(&:id)
    mismapped_hash = page_id_to_page_map.reject{ |page_id, page| all_pages_set.include? page }
    diag_info = mismapped_hash.map do |page_id, page|
      from_title = pages_by_id[page_id].try(:title) || 'nil'
      to_title  = page.try(:title) || 'nil'
      "#{from_title} => #{to_title}"
    end

    validity_error_messages << "Mismapped pages (to pages): [#{diag_info.join(', ')}]"
    self.is_valid = false
  end

  # Every value in the page_id_to_pool_type_exercises_map
  # is an array of exercises in the to_ecosystem for all pools
  def all_pages_map_to_exercises
    page_id_to_pool_type_exercises_map_values_set = \
      Set.new page_id_to_pool_type_exercises_map.values.flat_map(&:values)
    all_exercises_set                             = Set.new to_ecosystem.exercises

    return true if page_id_to_pool_type_exercises_map_values_set.subset?(all_exercises_set)

    mismapped_hash = {}
    page_id_to_pool_type_exercises_map.each do |page_id, pool_type_exercises_map|
      pool_type_exercises_map.each do |pool_type, exercises|
        exercises.each do |exercise|
          next if all_exercises_set.include? exercise

          mismapped_hash[page_id] ||= []
          mismapped_hash[page_id] << exercise
        end
      end
    end
    diag_info = mismapped_hash.map do |page_id, exercises|
      title = pages_by_id[page_id].try(:title) || 'nil'
      ex_uids  = exercises.map(&:uid)
      "#{title} => [#{ex_uids.join(', ')}]"
    end

    validity_error_messages << "Mismapped pages (to exercises): [#{diag_info.join(', ')}]"
    self.is_valid = false
  end
end
