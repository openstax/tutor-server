class GetUserTermsInfos

  lev_routine express_output: :infos

  uses_routine GetUserCourses, translations: { outputs: { type: :verbatim } }
  uses_routine Legal::GetContractNames, translations: { outputs: { type: :verbatim } }

  def exec(user)

    # Get contracts that apply to the user's current courses; some of these
    # have been signed by proxy (and need an implicit signature), while some
    # don't.  Return an array of hashes with info on each relevant contract

    run(GetUserCourses, user: user)
    run(Legal::GetContractNames,
        applicable_to: outputs.courses,
        contract_names_signed_by_everyone: [:general_terms_of_use, :privacy_policy])
    user_profile = user.to_model

    outputs.infos = []

    outputs.proxy_signed.each do |contract_name|
      FinePrint.sign_contract(profile, contract_name, FinePrint::SIGNATURE_IS_IMPLICIT) \
        if !FinePrint.signed_contract?(profile, contract_name)

      outputs.infos.push(info(contract_name, user_profile, true))
    end

    outputs.non_proxy_signed.each do |contract_name|
      outputs.infos.push(info(contract_name, user_profile, false))
    end

  end

  def info(contract_name, user_profile, is_proxy_signed)
    contract = FinePrint.get_contract(contract_name)
    is_signed = FinePrint.signed_contract?(user_profile, contract)
    has_signed_before = is_signed || FinePrint.signed_any_version_of_contract?(user_profile, contract)

    {
      id: contract.id,
      name: contract_name,
      title: contract.title,
      content: contract.content,
      version: contract.version,
      is_signed: is_signed,
      has_signed_before: has_signed_before,
      is_proxy_signed: is_proxy_signed
    }
  end
end
