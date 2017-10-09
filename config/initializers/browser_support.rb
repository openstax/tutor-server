Browser.modern_rules.clear

# a bit stricter version of
# https://github.com/fnando/browser/blob/master/lib/browser/browser.rb#L83-L90

Browser.modern_rules.tap do |rules|
  rules << ->(b) { b.safari? && b.version.to_i >= 10 }
  rules << ->(b) { b.chrome? }
  rules << ->(b) { b.firefox? }
  rules << ->(b) { b.ie? && b.version.to_i >= 11 && !b.compatibility_view? }
  rules << ->(b) { b.edge? && !b.compatibility_view? }
  rules << ->(b) { b.opera? && b.version.to_i >= 12 }
end


# Rails.configuration.middleware.use Browser::Middleware do
#   redirect_to browser_upgrade_path if request.env["PATH_INFO"] == '/dashboard' &&  !browser.modern?
# end
