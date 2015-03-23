require 'openstax_exchange'

class CreateUser

  lev_routine

  protected

  def exec(account)
    outputs[:user] = UserProfile::Profile.create do |user|
      user.entity_user = Entity::CreateUser.call.outputs.user
      user.account = account
      user.exchange_identifier = OpenStax::Exchange.create_identifier
    end

    transfer_errors_from(outputs[:user], {type: :verbatim})
  end
end
