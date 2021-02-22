require 'oauth2'

class OpenStax::Exercises::V1::RealClient
  NON_QUERY_PARAMS = ['order_by', 'page', 'per_page', 'ob', 'p', 'pp']

  attr_reader :server_url

  def initialize(exercises_configuration)
    @server_url = exercises_configuration.server_url
    @client_id  = exercises_configuration.client_id
    @secret     = exercises_configuration.secret
    @mutex      = Mutex.new
  end

  def request(*args)
    oauth_worker.request(*args)
  end

  def sanitize(vals)
    vals = [vals].flatten.map(&:to_s)

    # Remove , and "
    value_str = vals.map{ |val| val.gsub(/(?:,|"|%2C|%22)/, '') }.join(',')

    # If : or spaces present, quote all the values
    vals.any? { |val| /[\s:]/.match(val) } ? "\"#{value_str}\"" : value_str
  end

  def exercises(params = {}, options = {})
    params = params.stringify_keys
    query_hash = params.except(*NON_QUERY_PARAMS)
    query = query_hash.map { |key, vals| "#{key}:#{sanitize(vals)}" }.join(' ')
    uri = Addressable::URI.parse(@server_url)
    uri.path = '/api/exercises/search'
    body = { q: query }.merge(params.slice(*NON_QUERY_PARAMS)).to_query

    JSON.parse(request(:post, uri, with_accept_header(options.merge(body: body))).body)
  end

  protected

  def oauth_worker
    # Lazily instantiate the oauth client and token primarily to
    # ensure that Tutor can still boot if Exercises is offline

    return @oauth_worker unless @oauth_worker.nil?

    @mutex.synchronize do
      # Check the variable again now that we have obtained the mutex lock
      return @oauth_worker unless @oauth_worker.nil?

      oauth_client = OAuth2::Client.new(@client_id, @secret, site: @server_url)

      oauth_token = oauth_client.client_credentials.get_token \
        unless @client_id.nil?

      @oauth_worker = oauth_token || oauth_client
    end

    @oauth_worker
  end

  def with_accept_header(options = {})
    options[:headers] ||= {}
    options[:headers].merge!('Accept' => 'application/vnd.openstax.v1')
    options
  end
end
