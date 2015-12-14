class Admin::TargetedContractsCreate
  lev_handler uses: Legal::CreateTargetedContract

  paramify :targeted_contract do
    attribute :contract_name, type: String
    attribute :target, type: String
    attribute :is_proxy_signed, type: boolean
    attribute :is_end_user_visible, type: boolean
    attribute :masked_contract_names
  end

  protected

  def authorized?
    true # already authenticated in admin controller base
  end

  def handle
    masked_contract_names = targeted_contract_params.masked_contract_names.reject(&:blank?)
    target_gid, target_name = gid_and_name(targeted_contract_params.target)

    run(:legal_create_targeted_contract,
        contract_name: targeted_contract_params.contract_name,
        target_gid: target_gid,
        target_name: target_name,
        masked_contract_names: masked_contract_names,
        is_proxy_signed: targeted_contract_params.is_proxy_signed,
        is_end_user_visible: targeted_contract_params.is_end_user_visible)
  end

  def gid_and_name(target)
    target.split('|')
  end
end
