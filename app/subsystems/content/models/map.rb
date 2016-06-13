class Content::Models::Map < Tutor::SubSystems::BaseModel
  belongs_to :from_ecosystem, class_name: '::Content::Models::Ecosystem', inverse_of: :to_maps
  belongs_to :to_ecosystem, class_name: '::Content::Models::Ecosystem', inverse_of: :from_maps

  validates :from_ecosystem, :to_ecosystem, presence: true
  validates :to_ecosystem, uniqueness: { scope: :content_from_ecosystem_id }

  before_validation :validate_maps

  protected

  def validate_maps
    self.is_valid = true
    self.validity_messages = []

    ensure_all_exercises_are_mapped
    ensure_all_exercises_map_to_pages
    ensure_all_pages_are_mapped
    ensure_all_pages_map_to_pages
    ensure_all_pages_map_to_exercises
  end

  # Every exercise in the from_ecosystem is a key in the exercise_id_to_page_map
  def all_exercises_are_mapped
    all_exercises                    = from_ecosystem.exercises
    exercise_id_to_page_map_keys_set = Set.new(exercise_id_to_page_map.keys)
    exercise_ids_set                 = Set.new(all_exercises.map(&:id))

    if exercise_id_to_page_map_keys_set != exercise_ids_set
      unmapped_ids = exercise_ids_set - exercise_id_to_page_map_keys_set
      unmapped_uids = all_exercises.select{|ex| unmapped_exercise_ids.include? ex.id }.map(&:uid)
      validity_messages << "Unmapped exercise uids: [#{unmapped_uids.to_a.join(', ')}]\n"
      self.is_valid = false
    else
      false
    end
  end

  # Every value in the exercise_id_to_page_map is a page in the to_ecosystem
  def all_exercises_map_to_pages
    all_execises_map_pages_set = Set.new(all_exercises_map.values)
    to_ecosystem_pages_set     = Set.new(to_ecosystem_pages)

    condition = all_execises_map_pages_set.subset?(to_ecosystem_pages_set)

    condition_message =
      if condition
        "all exercises map to pages"
      else
        mismapped_pages = all_execises_map_pages_set - to_ecosystem_pages_set
        mismapped_hash  = all_exercises_map.select{|ex,page| mismapped_pages.include? page }
        diag_info = mismapped_hash.map do |ex_id,page|
          ex_uid = all_exercises.detect{|ex| ex.id == ex_id}.uid
          title  = page.try(:title) || 'nil'
          "#{ex_uid} => #{title}"
        end
        "mismapped exercises: #{diag_info.join(', ')}"
      end
    return condition, condition_message
  end

  # Every page in the from_ecosystem is a key in the page_id_to_pages_map
  # and in the pool_type_page_id_to_exercises_map for all pools
  def all_pages_are_mapped
    all_pages_map_ids_set = Set.new(all_pages_map.keys)
    all_page_ids_set      = Set.new(all_pages.map(&:id))

    condition = all_pages_map_ids_set == all_page_ids_set

    condition_message =
      if condition
        "no unmapped pages"
      else
        unmapped_page_ids = all_page_ids_set - all_pages_map_ids_set
        unmapped_page_titles = all_pages.select{|page| unmapped_page_ids.include? page.id } \
                                        .map(&:title)
        "unmapped page titles: #{unmapped_page_titles.to_a.join(', ')}"
      end
    return condition, condition_message
  end

  # Every value in the page_id_to_pages_map is a page in the to_ecosystem
  def all_pages_map_to_pages
    all_pages_map_exercises_set = Set.new(all_pages_map.values.flatten)
    to_ecosystem_exercises_set  = Set.new(to_ecosystem_exercises)

    condition = all_pages_map_exercises_set.subset?(to_ecosystem_exercises_set)

    condition_message =
      if condition
        "all pages map to exercise sets"
      else
        mismapped_exercises = all_pages_map_exercises_set - to_ecosystem_exercises_set
        mismapped_hash  = all_pages_map.select{|page,exs| (exs & mismapped_exercises).any? }
        diag_info = mismapped_hash.map do |page_id,exs|
          title = all_pages.detect{|pg| pg.id == page_id}.title
          ex_uids  = exs.map(&:uid)
          "#{title} => [#{ex_uids.join(', ')}]"
        end
        "mismapped pages: #{diag_info.join(', ')}"
      end
    return condition, condition_message
  end

  # Every value in the pool_type_page_id_to_exercises_map
  # is an array of exercises in the to_ecosystem for all pools
  def all_pages_map_to_exercises
    all_pages_map_exercises_set = Set.new(all_pages_map.values.flatten)
    to_ecosystem_exercises_set  = Set.new(to_ecosystem_exercises)

    condition = all_pages_map_exercises_set.subset?(to_ecosystem_exercises_set)

    condition_message =
      if condition
        "all pages map to exercise sets"
      else
        mismapped_exercises = all_pages_map_exercises_set - to_ecosystem_exercises_set
        mismapped_hash  = all_pages_map.select{|page,exs| (exs & mismapped_exercises).any? }
        diag_info = mismapped_hash.map do |page_id,exs|
          title = all_pages.detect{|pg| pg.id == page_id}.title
          ex_uids  = exs.map(&:uid)
          "#{title} => [#{ex_uids.join(', ')}]"
        end
        "mismapped pages: #{diag_info.join(', ')}"
      end
    return condition, condition_message
  end
end
