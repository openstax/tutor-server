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
        # Adapted from Tsugi. Because Canvas uses the same issuer for all deployments, breaking the
        # spec, we have to add our own guid parameter to the login and other URLs to distinguish
        # between different Canvas deployments.
        session['lti_guid'] = params['tutor_guid']

        # LMS is misconfigured in Tutor
        return fail!(:invalid_issuer) unless params['iss'] == issuer

        super
      rescue ActiveRecord::RecordNotFound => exception
        # LMS is not configured at all in Tutor
        fail! :invalid_guid, exception
      end

      def callback_phase
        # The ID token code itself already verifies the issuer here
        super
      rescue ActiveRecord::RecordNotFound => exception
        # Either they are not allowing cookies from Tutor or they used the back button
        # after finishing the login
        fail! :missing_guid, exception
      rescue ::OpenIDConnect::ResponseObject::IdToken::InvalidToken => exception
        fail!(
          case exception
          when ::OpenIDConnect::ResponseObject::IdToken::ExpiredToken
            # Server clock wrong or replay attack
            :expired_token
          when ::OpenIDConnect::ResponseObject::IdToken::InvalidIssuer
            # LMS is misconfigured in Tutor (Issuer)
            :invalid_issuer
          when ::OpenIDConnect::ResponseObject::IdToken::InvalidNonce
            # Replay attack
            :invalid_nonce
          when ::OpenIDConnect::ResponseObject::IdToken::InvalidAudience
            # LMS is misconfigured in Tutor (Client ID)
            :invalid_audience
          else
            # Unknown token error
            :invalid_token
          end, exception
        )
      end

      # Adapted from Tsugi. Because Canvas uses the same issuer for all deployments, breaking the
      # spec, we have to add our own guid parameter to the login and other URLs to distinguish
      # between different Canvas deployments.
      def guid
        session['lti_guid']
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
      # We must patch the OpenID Connect strategy to do this
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
          lti_message_hint: params['lti_message_hint'] # this is the patch
        }

        opts.merge!(options.extra_authorize_params) unless options.extra_authorize_params.empty?

        client.authorization_uri(opts.reject { |_k, v| v.nil? })
      end

      # We want discovery to be OFF in general but we do want to use JWKS
      # Extracted from the openid_connect gem and moved here so it runs when discovery is false
      def public_key
        @public_key ||= JSON::JWK::Set.new JSON.parse(
          ::OpenIDConnect.http_client.get_content(client_options.jwks_uri)
        ).with_indifferent_access[:keys]
      end
    end
  end
end
