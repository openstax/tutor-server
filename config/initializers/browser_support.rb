Browser.modern_rules.clear

# a bit stricter version of
# https://github.com/fnando/browser/blob/master/lib/browser/browser.rb#L83-L90

Browser.modern_rules.tap do |rules|
  rules << ->(b) { b.safari? && b.version.to_i >= 9 }
  rules << ->(b) { b.chrome? }
  rules << ->(b) { b.firefox? }
  rules << ->(b) { b.edge? && !b.compatibility_view? }
  rules << ->(b) { b.opera? && b.version.to_i >= 12 }
end
