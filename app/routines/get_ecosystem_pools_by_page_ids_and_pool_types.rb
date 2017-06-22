class GetEcosystemPoolsByPageIdsAndPoolTypes

  lev_routine transaction: :no_transaction, express_output: :pools_map

  protected

  def exec(ecosystem:, page_ids: nil, pool_types: nil)
    pages = page_ids.nil? ? ecosystem.pages : ecosystem.pages_by_ids(page_ids)

    pool_types = [pool_types].flatten.compact.uniq

    # Default to all types
    pool_types = Content::Pool.pool_types if pool_types.empty?

    # Build map of pool types to pools
    outputs[:pools_map] = pool_types.each_with_object({}) do |pool_type, result|
      pool_method_name = "#{pool_type}_pools".to_sym
      result[pool_type] = ecosystem.send(pool_method_name, pages: pages)
    end
  end
end
