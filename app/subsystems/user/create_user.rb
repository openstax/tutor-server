module User
  class CreateUser
    lev_routine express_output: :user

    uses_routine OpenStax::Accounts::FindOrCreateAccount,
      translations: { outputs: { type: :verbatim } },
      as: :find_or_create_account

    protected

    def exec(account_id: nil, email: nil, username: nil, password: nil,
             first_name: nil, last_name: nil, full_name: nil, title: nil,
             faculty_status: nil, salesforce_contact_id: nil)
      raise ArgumentError, 'Requires either an email, a username or an account_id' \
        if email.nil? && username.nil? && account_id.nil?

      account_id ||= find_or_create_account_id(
        email: email, username: username, password: password,
        first_name: first_name, last_name: last_name,
        full_name: full_name, title: title,
        faculty_status: faculty_status, salesforce_contact_id: salesforce_contact_id
      )

      outputs.user = ::User::User.create account_id: account_id

      transfer_errors_from(outputs.user.to_model, type: :verbatim)
    end

    def find_or_create_account_id(attrs)
      run(:find_or_create_account, attrs).outputs.account.id
    end
  end
end
