class GetPageExerciseIdsByPoolTypes
  lev_routine transaction: :no_transaction, express_output: :exercise_ids_by_pool_type

  protected

  def exec(ecosystem:, page_ids: nil, pool_types: nil)
    pool_types = [ pool_types ].flatten.compact.uniq

    # Default to all types
    pool_types = Content::Models::Page.pool_types if pool_types.empty?

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
        page.send pool_method_name_by_pool_type[pool_type]
      end
    end
  end
end
