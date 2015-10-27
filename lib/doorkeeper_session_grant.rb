module Doorkeeper

  configuration.token_grant_types << "session"

  module SessionGrantExtensions
    def self.included(base)
      base.include ActionController::Helpers
      base.include ActionController::Cookies
    end

    def current_user
      @current_user_manager ||= \
         OpenStax::Accounts::CurrentUserManager.new(request, session, cookies)
      @current_user_manager.current_user
    end
  end

  TokensController.send(:include, SessionGrantExtensions)

  class Server
    def resource_owner_from_session
      context.instance_eval do
        current_user.is_anonymous? ? nil : current_user
      end
    end
  end

  module Request
    class Session
      def self.build(server)
        new(server.credentials, server.resource_owner_from_session, server)
      end

      attr_accessor :credentials, :resource_owner, :server

      def initialize(credentials, resource_owner, server)
        @credentials, @resource_owner, @server = credentials, resource_owner, server
      end

      def request
        @request ||= OAuth::PasswordAccessTokenRequest.new(
                       Doorkeeper.configuration,
                       credentials,
                       resource_owner,
                       server.parameters)
      end

      def authorize
        request.authorize
      end
    end
  end

end



