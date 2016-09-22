OpenStax::Biglearn::Api::RealClient.class_exec do
  # Sort learners and pool_ids for consistent cassettes
  def request_clues_with_sort(learners:, pool_ids:, pool_id_to_cache_key_map:, result_map:)
    request_clues_without_sort(learners: learners.sort, pool_ids: pool_ids.sort,
                               pool_id_to_cache_key_map: pool_id_to_cache_key_map,
                               result_map: result_map)
  end

  alias_method_chain :request_clues, :sort
end
