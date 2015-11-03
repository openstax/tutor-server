module Doorkeeper

  # Let Doorkeeper accept a custom grant type of "session"
  configuration.token_grant_types << "session"

  # The new grant type of "session" is used by Doorkeeper to infer the
  # existence of a Doorkeeper::Request::Session object that handles this
  # grant type.  This implementation is a stripped-down version of the
  # code in https://github.com/doorkeeper-gem/doorkeeper-grants_assertion

  module Request
    class Session
      def self.build(server)
        new(server)
      end

      def initialize(server)
        @server = server
      end

      def request
        return @request if @request

        current_user = @server.context.current_user
        current_user = nil if current_user.is_anonymous?

        @request = OAuth::PasswordAccessTokenRequest.new(
                       Doorkeeper.configuration,
                       nil, # 'credentials', unused
                       current_user,
                       @server.parameters)
      end

      def authorize
        request.authorize
      end
    end
  end

end
