module Doorkeeper

  # Let Doorkeeper accept a custom grant type of "session"

  configuration.token_grant_types << "session"

  # The TokensController is bare bones; add knowledge of helpers and cookies
  # as well as how to get the session user

  module TokensControllerExtensions
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

  TokensController.send(:include, TokensControllerExtensions)

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

        tokens_controller = @server.context
        current_user = tokens_controller.current_user
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
