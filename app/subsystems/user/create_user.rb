module User
  class CreateUser
    lev_routine outputs: {
      user: :_self,
      _verbatim: { name: OpenStax::Accounts::FindOrCreateAccount,
                   as: :find_or_create_account }
    }

    protected
    def exec(account_id: nil, exchange_identifiers: nil,
             email: nil, username: nil, password: nil,
             first_name: nil, last_name: nil, full_name: nil, title: nil)

      if email.nil? && username.nil? && account_id.nil?
        raise ArgumentError, 'Requires either an email, a username or an account_id'
      end

      account_id ||= find_or_create_account_id(
        email: email, username: username, password: password,
        first_name: first_name, last_name: last_name,
        full_name: full_name, title: title
      )

      identifiers = exchange_identifiers || new_identifiers

      set(user: User.create(exchange_read_identifier: identifiers.read,
                            exchange_write_identifier: identifiers.write,
                            account_id: account_id))

      transfer_errors_from(result.user.to_model, type: :verbatim)
    end

    private
    def new_identifiers
      @identifiers ||= OpenStax::Exchange.create_identifiers
    end

    def find_or_create_account_id(attrs)
      run(:find_or_create_account, attrs).account.id
    end
  end
end
