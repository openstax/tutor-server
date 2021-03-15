class GetPageExerciseIdsByPoolTypes
  lev_routine transaction: :no_transaction, express_output: :exercise_ids_by_pool_type

  uses_routine GetCourseEcosystem, as: :get_ecosystem

  protected

  def exec(ecosystem: nil, course: nil, page_ids: nil, exercise_ids: nil, pool_types: nil)
    raise ArgumentError, "Either :ecosystem or :course must be provided" \
      if ecosystem.nil? && course.nil?

    ecosystem ||= run(:get_ecosystem, course: course).outputs.ecosystem

    exercise_ids_set = Set.new(exercise_ids.map(&:to_i)) unless exercise_ids.nil?
    pool_types = [ pool_types ].flatten.compact.uniq

    # Default to all types
    pool_types = Content::Models::Page::POOL_TYPES if pool_types.empty?

    pool_method_name_by_pool_type = {}
    pool_types.each do |pool_type|
      pool_method_name_by_pool_type[pool_type] = "#{pool_type}_exercise_ids".to_sym
    end

    pages = if page_ids.nil?
      ecosystem.pages
    elsif ecosystem.pages.loaded?
      page_ids = page_ids.map(&:to_i)
      ecosystem.pages.select { |page| page_ids.include? page.id }
    else
      ecosystem.pages.select(*pool_method_name_by_pool_type.values).where(id: page_ids)
    end

    # Build map of pool types to pools
    outputs.exercise_ids_by_pool_type = {}
    pool_types.each do |pool_type|
      outputs.exercise_ids_by_pool_type[pool_type] = pages.flat_map do |page|
        page_exercise_ids = page.send pool_method_name_by_pool_type[pool_type]
        next page_exercise_ids if exercise_ids_set.nil?

        page_exercise_ids.select { |exercise_id| exercise_ids_set.include? exercise_id }
      end
    end

    # Add teacher-created exercises if course is provided
    return if course.nil?

    teacher_exercise_ids = Content::Models::Exercise.where(
      content_page_id: pages.map(&:id), user_profile_id: course.related_teacher_profile_ids
    ).pluck(:id)

    pool_types.each do |pool_type|
      outputs.exercise_ids_by_pool_type[pool_type].concat teacher_exercise_ids
    end
  end
end
