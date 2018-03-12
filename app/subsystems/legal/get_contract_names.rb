class Legal::GetContractNames
  lev_routine

  protected

  def exec(applicable_to:, contract_names_signed_by_everyone: [])
    applicable_to = [applicable_to].flatten.compact

    targeted_contracts = Legal::GetTargetedContracts[applicable_to: applicable_to]

    proxy_signed_contracts, non_proxy_signed_contracts =
      targeted_contracts.partition(&:is_proxy_signed)

    outputs.proxy_signed =
      proxy_signed_contracts.map(&:contract_name).uniq


    # Figure out which remaining contracts need to be signed and then have
    # FinePrint take care of it.

    contract_names_signed_by_everyone =
      contract_names_signed_by_everyone.map(&:to_s)

    contracts_masked_by_targeted_contracts =
      targeted_contracts.map(&:masked_contract_names)
                        .flatten.compact.uniq

    targeted_contracts_without_proxy_signature =
      non_proxy_signed_contracts.map(&:contract_name)
                                .uniq

    outputs.non_proxy_signed =
      ( contract_names_signed_by_everyone -
        contracts_masked_by_targeted_contracts ) +
      targeted_contracts_without_proxy_signature
  end
end
