class GetPageExerciseIdsByPoolTypes
  lev_routine transaction: :no_transaction, express_output: :exercise_ids_by_pool_type

  protected

  def exec(ecosystem:, page_ids: nil, exercise_ids: nil, pool_types: nil)
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
  end
end
