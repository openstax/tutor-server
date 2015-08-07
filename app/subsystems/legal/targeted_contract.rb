class Legal::TargetedContract

  def initialize(repository)
    @repository = repository
  end

  delegate :target_gid, :target_name, :contract_name, :masked_contract_names,
           :is_proxy_signed, :is_end_user_visible, :id,
           to: :repository

  protected

  attr_reader :repository
end
