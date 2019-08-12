module User
  class CreateUser
    lev_routine express_output: :user

    uses_routine OpenStax::Accounts::FindOrCreateAccount,
      as: :find_or_create_account,
      translations: { outputs: { type: :verbatim } }

    protected

    def exec(account_id: nil, email: nil, username: nil, password: nil, first_name: nil,
             last_name: nil, full_name: nil, title: nil, faculty_status: nil,
             salesforce_contact_id: nil, role: nil, school_type: nil, is_test: nil)
      raise ArgumentError, 'Requires either an email, a username or an account_id' \
        if email.nil? && username.nil? && account_id.nil?

      account_id ||= run(
        :find_or_create_account,
        email: email,
        username: username,
        password: password,
        first_name: first_name,
        last_name: last_name,
        full_name: full_name,
        title: title,
        faculty_status: faculty_status,
        salesforce_contact_id: salesforce_contact_id,
        role: role,
        school_type: school_type,
        is_test: is_test
      ).outputs.account.id

      outputs.user = ::User::User.create account_id: account_id

      transfer_errors_from(outputs.user.to_model, type: :verbatim)
    end
  end
end
