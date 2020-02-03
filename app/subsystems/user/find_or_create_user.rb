module User
  class FindOrCreateUser
    lev_routine express_output: :user

    uses_routine OpenStax::Accounts::FindOrCreateAccount, as: :find_or_create_account

    protected

    def exec(account_id: nil, email: nil, username: nil, password: nil, first_name: nil,
             last_name: nil, full_name: nil, title: nil, faculty_status: nil,
             salesforce_contact_id: nil, role: nil, school_type: nil, is_test: nil)
      raise ArgumentError, 'Requires either an email, a username or an account_id' \
        if email.nil? && username.nil? && account_id.nil?

      retry_count = 0
      begin
        outputs.user = ::User::Models::Profile.transaction(requires_new: true) do
          if account_id.present?
            ::User::Models::Profile.find_or_create_by account_id: account_id
          else
            account = run(
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
            ).outputs.account

            ::User::Models::Profile.find_or_create_by account: account
          end
        end
      rescue RuntimeError, ActiveRecord::RecordNotUnique, ::PG::UniqueViolation
        raise if retry_count >= 3

        retry_count += 1
        retry
      end

      transfer_errors_from outputs.user, type: :verbatim
    end
  end
end
