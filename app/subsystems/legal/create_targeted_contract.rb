class Legal::CreateTargetedContract
  lev_routine express_output: :targeted_contract

  protected

  def exec(contract_name:, target_gid:, target_name:, is_proxy_signed: false, is_end_user_visible: true, masked_contract_names: nil)
    # verify that contract name and masked contract names exist

    used_contract_names = ([contract_name] + masked_contract_names).flatten.compact

    if (used_contract_names - FinePrint::Contract.all).any?
      fatal_error(code: :contract_does_not_exist)
    end

    outputs[:targeted_contract] =
      Legal::Models::TargetedContract.create(contract_name: contract_name,
                                             target_gid: target_gid,
                                             target_name: target_name,
                                             is_proxy_signed: is_proxy_signed,
                                             is_end_user_visible: is_end_user_visible,
                                             masked_contract_names: masked_contract_names)

    transfer_errors_from(outputs.targeted_contract, {type: :verbatim})
  end

end
