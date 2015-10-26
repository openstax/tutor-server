module Doorkeeper

  class Config
    option :resource_owner_from_session, default: (lambda do |routes|
        warn(I18n.t("doorkeeper.errors.messages.session_flow_not_configured"))
        nil
      end)
  end


  module GrantsAssertion
    def resource_owner_from_session
      instance_eval(&Doorkeeper.configuration.resource_owner_from_session)
    end
  end

  Doorkeeper::Helpers::Controller.send :include, Doorkeeper::GrantsAssertion

  class Server
    def resource_owner_from_session
      context.send :resource_owner_from_session
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
        @request ||= OAuth::PasswordAccessTokenRequest.new(Doorkeeper.configuration, credentials, resource_owner, server.parameters)
      end

      def authorize
        request.authorize
      end
    end
  end
end
