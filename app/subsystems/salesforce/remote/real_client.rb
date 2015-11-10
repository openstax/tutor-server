class Salesforce::Remote::RealClient < Restforce::Data::Client

  def initialize
    user = Salesforce::Models::User.first
    raise IllegalState, "a salesforce user must be set!" if user.nil?
    secrets = secrets = Rails.application.secrets['salesforce']
    super(oauth_token: user.oauth_token,
          refresh_token: user.refresh_token,
          instance_url: user.instance_url,
          client_id: secrets['consumer_key'],
          client_secret: secrets['consumer_secret'])
  end

end
