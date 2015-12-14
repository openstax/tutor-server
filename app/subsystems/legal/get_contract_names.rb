class Legal::GetContractNames
  lev_routine outputs: { proxy_signed: :_self,
                         non_proxy_signed: :_self }

  protected

  def exec(applicable_to:, contract_names_signed_by_everyone: [])
    applicable_to = [applicable_to].flatten.compact

    targeted_contracts = applicable_to.collect { |item|
      Legal::GetTargetedContracts.call(applicable_to: item)
    }.flatten

    proxy_signed_contracts, non_proxy_signed_contracts =
      targeted_contracts.partition(&:is_proxy_signed)

    set(proxy_signed: proxy_signed_contracts.collect(&:contract_name).uniq)


    # Figure out which remaining contracts need to be signed and then have
    # FinePrint take care of it.

    contract_names_signed_by_everyone =
      contract_names_signed_by_everyone.collect(&:to_s)

    contracts_masked_by_targeted_contracts =
      targeted_contracts.collect(&:masked_contract_names)
                        .flatten.compact.uniq

    targeted_contracts_without_proxy_signature =
      non_proxy_signed_contracts.collect(&:contract_name)
                                .uniq

    set(non_proxy_signed: (contract_names_signed_by_everyone -
                            contracts_masked_by_targeted_contracts) +
                          targeted_contracts_without_proxy_signature)
  end
end
