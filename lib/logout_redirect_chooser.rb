# Based on a request, choose where to redirect folks who are logging out (or
# return nil if some outside default redirect should be used)

class LogoutRedirectChooser

  def initialize(request_url)
    @url = request_url
  end

  def choose(default: nil)
    if url_indicates_concept_coach?
      cc_redirect_url
    else
      default
    end
  end

  def cc_redirect_url
    subdomain = uri.host.split('.')[0]

    suffix = case subdomain
             when /localhost/
               "-localhost"
             when /-(\w+)/
               "-" + $1
             else
               ""
             end

    "http://cc.openstax.org/logout#{suffix}"
  end

  private

  def url_indicates_concept_coach?
    @url.match(/\/ConceptCoach\//i) ||
    to_bool(query_hash['cc'])
  end

  def query_hash
    uri.query.nil? ? {} : URI::decode_www_form(uri.query).to_h
  end

  def uri
    @uri ||= URI.parse(@url)
  end

  def to_bool(boolean_thing)
    ActiveRecord::Type::Boolean.new.type_cast_from_user(boolean_thing)
  end

end
