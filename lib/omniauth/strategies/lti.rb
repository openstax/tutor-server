# frozen_string_literal: true
# Based on https://github.com/m0n9oose/omniauth_openid_connect/blob/master/lib/omniauth/strategies/openid_connect.rb
# Modified to be database-backed to support multiple providers (LMS's)

module OmniAuth
  module Strategies
    class Lti < OpenIDConnect
      def initialize(*args)
        super

        # The initialization process uses #options but we do not want to cache them between requests
        # Clear the variable when initialization is complete so we'll get a new one for each request
        @lti_options = nil
      end

      # Normally options are cached during initialization but in our case the settings change
      # depending on the LTI platform, so we use a custom class to handle that
      def options
        @lti_options ||= ::Lti::Options.new super, self
      end

      # The following 3 methods just handle missing LTI platforms so we can get an error message

      def request_phase
        super
      rescue ActiveRecord::RecordNotFound => e
        fail!(:invalid_issuer_or_deployment_id, e)
      end

      def callback_phase
        super
      rescue ActiveRecord::RecordNotFound => e
        fail!(:invalid_issuer_or_deployment_id, e)
      end

      def other_phase
        super
      rescue ActiveRecord::RecordNotFound => e
        fail!(:invalid_issuer_or_deployment_id, e)
      end

      # The issuer for an Omniauth provider is normally fixed,
      # but in LTI it is used to choose the platform
      def issuer
        params['iss']
      end

      def deployment_id
        params['lti_deployment_id']
      end

      def platform
        @platform ||= ::Lti::Platform.find_by! issuer: issuer
      end
    end
  end
end
