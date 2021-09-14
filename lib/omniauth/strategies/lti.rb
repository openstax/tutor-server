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
        raise ::OpenIDConnect::ResponseObject::IdToken::InvalidIssuer.new(
          'Issuer does not match'
        ) unless params['iss'] == issuer

        super
      rescue ActiveRecord::RecordNotFound => e
        fail!(:invalid_guid, e)
      rescue OpenIDConnect::ResponseObject::IdToken::InvalidIssuer => e
        fail!(:invalid_issuer, e)
      end

      def callback_phase
        # The ID token code itself already verifies the issuer here
        super
      rescue ActiveRecord::RecordNotFound => e
        fail!(:invalid_guid, e)
      rescue OpenIDConnect::ResponseObject::IdToken::InvalidIssuer => e
        fail!(:invalid_issuer, e)
      end

      # Adapted from Tsugi. Because Canvas uses the same issuer for all deployments, breaking the
      # spec, we have to add our own guid parameter to the login and other URLs to distinguish
      # between different Canvas deployments.
      def guid
        params['guid']
      end

      def platform
        @platform ||= ::Lti::Platform.find_by! guid: guid
      end

      # The issuer for an Omniauth provider is normally fixed,
      # but in LTI it is used to choose the platform
      def issuer
        platform.issuer
      end

      # The LTI spec adds an extra lti_message_hint param that needs to be sent back to the platform
      # We cannot use extra_authorize_params because it is static
      def authorize_uri
        client.redirect_uri = redirect_uri
        opts = {
          response_type: options.response_type,
          response_mode: options.response_mode,
          scope: options.scope,
          state: new_state,
          login_hint: params['login_hint'],
          ui_locales: params['ui_locales'],
          claims_locales: params['claims_locales'],
          prompt: options.prompt,
          nonce: (new_nonce if options.send_nonce),
          hd: options.hd,
          acr_values: options.acr_values,
          lti_message_hint: params['lti_message_hint']
        }

        opts.merge!(options.extra_authorize_params) unless options.extra_authorize_params.empty?

        client.authorization_uri(opts.reject { |_k, v| v.nil? })
      end

      # We want discovery OFF in general but we do want to use JWKS
      # Extracted from the openid_connect gem
      def public_key
        @public_key ||= JSON::JWK::Set.new JSON.parse(
          ::OpenIDConnect.http_client.get_content(client_options.jwks_uri)
        ).with_indifferent_access[:keys]
      end
    end
  end
end
