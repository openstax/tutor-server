# Be sure to restart your server when you modify this file.

# Define an application-wide content security policy
# For further information see the following documentation
# https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Content-Security-Policy

# We currently use at least the following sources in the home page and/or My Courses:
# self - connect, script, style, img
# https://accounts.openstax.org - connect
# https://ajax.googleapis.com - script
# https://random-looking-domain.salesforceliveagent.com - script
# https://cdnjs.cloudflare.com - connect, script, font
# https://js.pulseinsights.com - script
# https://www.googletagmanager.com - script
# https://survey.pulseinsights.com - script
# https://snap.licdn.com - script
# https://www.googleadservices.com - script
# https://static.ads-twitter.com - script
# https://cdn.abrankings.com - connect, script
# https://googleads.g.doubleclick.net - connect, script
# https://analytics.twitter.com - script
# https://www.google-analytics.com - connect, script, img
# https://fonts.googleapis.com - style
# https://www.google.com - img
# https://px.ads.linkedin.com - img
# https://t.co - img
# https://fonts.gstatic.com - font

Rails.application.config.content_security_policy do |policy|
  default_src = [ :self ]

  connect_src = [ :self, :https ]

  font_src = [ :self, :https, :data ] # The frontend loads font data blobs
  img_src = [ :self, :https ]
  # Once we are in Rails 6 we can try getting rid of unsafe_inline by using nonces
  script_src = [ :self, :https, :unsafe_inline ]
  style_src = [ :self, :https, :unsafe_inline ]
  frame_src = [ :self, :https ]

  if Rails.env.development?
    # Local ports:
    # 2999 - OpenStax Accounts
    # 3035 - Webpacker using dev_server configuration
    # 8000 - Webpacker using default configuration
    connect_src += [
      'http://localhost:2999',
      'http://localhost:3035',
      'http://localhost:8000',
      'ws://localhost:3035',
      'ws://localhost:8000'
    ]

    font_src += [ 'http://localhost:3035', 'http://localhost:8000',  ]
    img_src += [ 'http://localhost:3035', 'http://localhost:8000' ]
    script_src += [ 'http://localhost:3035', 'http://localhost:8000' ]

    # This doesn't seem to be currently necessary
    # style_src += [ 'http://localhost:3035', 'http://localhost:8000' ]
  end

  policy.default_src *default_src

  policy.connect_src *connect_src

  policy.font_src *font_src
  policy.img_src *img_src
  policy.script_src *script_src
  policy.style_src *style_src
  policy.frame_src *frame_src

  # Specify URI for violation reports
  secrets = Rails.application.secrets
  sentry_secrets = secrets.sentry
  unless sentry_secrets.blank?
    uri = Addressable::URI.parse sentry_secrets[:csp_report_uri]
    query_values = { 'sentry_environment' => secrets.environment_name }
    query_values['sentry_release'] = secrets.release_version unless secrets.release_version.blank?
    uri.query_values = query_values.merge uri.query_values
    policy.report_uri uri.to_s
  end
end

# If you are using UJS then enable automatic nonce generation
# Rails.application.config.content_security_policy_nonce_generator = -> request { SecureRandom.base64(16) }

# Report CSP violations to a specified URI
# For further information see the following documentation:
# https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Content-Security-Policy-Report-Only

# TODO: Remove after 1 release
Rails.application.config.content_security_policy_report_only = IAm.real_production?
