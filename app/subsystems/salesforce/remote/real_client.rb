class SalesforceUserMissing < StandardError; end

class Salesforce::Remote::RealClient < Restforce::Data::Client

  def initialize
    user = Salesforce::Models::User.first
    if user.nil?
      Rails.logger.error { "The Salesforce client was requested but no user is available." }
      raise SalesforceUserMissing
    end
    secrets = Rails.application.secrets['salesforce']
    super(oauth_token: user.oauth_token,
          refresh_token: user.refresh_token,
          instance_url: user.instance_url,
          client_id: secrets['consumer_key'],
          client_secret: secrets['consumer_secret'],
          api_version: '29.0')
  end

end
