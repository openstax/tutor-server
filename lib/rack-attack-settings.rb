# Set up rack-attack settings

class Rack::Attack

  def self.routes
    if @routes.nil?
      Rails.application.reload_routes!
      @routes = UrlGenerator.new
    end
    @routes
  end

  throttle(routes.api_log_entry_path, limit: 50, period: 1.day) do |req|
    req.ip if req.path.starts_with?(routes.api_log_entry_path) && req.post?
  end

end

# Monkey-patch the rack-attack Request object (this is where the author says to do this)

class Rack::Attack::Request

  def throttled?
    env['rack.attack.match_type'] == :throttle
  end

  def is_first_one_throttled?
    throttled? && match_data[:count] == match_data[:limit] + 1
  end

  def matched_path
    env['rack.attack.matched']
  end

  def period
    match_data[:period]
  end

  def log_throttled!
    Rails.logger.info "Throttled #{ip} on #{matched_path}. Throttling continues (without further " \
                      "logging) until the next #{period} second interval."
  end

  protected

  def match_data
    @match_data ||= env['rack.attack.match_data']
  end
end

# Log events

ActiveSupport::Notifications.subscribe("rack.attack") do |name, start, finish, request_id, req|
  req.log_throttled! if req.is_first_one_throttled?
end
