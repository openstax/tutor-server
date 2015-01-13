require 'openstax_exchange'

class CreateUser

  lev_routine

  protected

  def exec(account)
    outputs[:user] = User.create do |user|
      user.account = account
      user.exchange_identifier = OpenStax::Exchange.create_identifier
    end

    transfer_errors_from(outputs[:user], {type: :verbatim})
  rescue StandardError => error
    fatal_error(code: :exception_raised, data: error)
  end

end
