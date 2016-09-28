require 'oauth2'

class OpenStax::Exercises::V1::RealClient

  NON_QUERY_PARAMS = ['order_by', 'page', 'per_page', 'ob', 'p', 'pp']

  attr_reader :server_url

  def initialize(exercises_configuration)
    @server_url   = exercises_configuration.server_url
    @client_id    = exercises_configuration.client_id
    @secret       = exercises_configuration.secret

    @oauth_client = OAuth2::Client.new(@client_id, @secret, site: @server_url)

    @oauth_token  = @oauth_client.client_credentials.get_token unless @client_id.nil?
  end

  def request(*args)
    (@oauth_token || @oauth_client).request(*args)
  end

  def sanitize(vals)
    vals = [vals].flatten.map(&:to_s)

    # Remove , and "
    value_str = vals.map{ |val| val.gsub(/(?:,|"|%2C|%22)/, '') }.join(',')

    # If : or spaces present, quote all the values
    vals.any?{ |val| /[\s:]/.match(val) } ? "\"#{value_str}\"" : value_str
  end

  def exercises(params = {}, options = {})
    params = params.stringify_keys
    query_hash = params.except(*NON_QUERY_PARAMS)
    query = query_hash.map{ |key, vals| "#{key}:#{sanitize(vals)}" }.join(' ')
    uri = Addressable::URI.parse(@server_url)
    uri.path = "/api/exercises"
    uri.query = {q: query}.merge(params.slice(*NON_QUERY_PARAMS)).to_query

    JSON.parse(request(:get, uri, with_accept_header(options)).body)
  end

  private

  def with_accept_header(options = {})
    options[:headers] ||= {}
    options[:headers].merge!('Accept' => 'application/vnd.openstax.v1')
    options
  end

end
