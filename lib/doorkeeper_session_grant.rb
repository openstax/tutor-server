module Doorkeeper

  class Config
    option :resource_owner_from_session, default: (lambda do |routes|
        warn("Session flow not configured")
        nil
      end)
  end

  class Server
    def resource_owner_from_session
      #context.send :resource_owner_from_session
      context.instance_eval(&Doorkeeper.configuration.resource_owner_from_session)
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
