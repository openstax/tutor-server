# Based on a request, choose where to redirect folks who are logging out (or
# return nil if some outside default redirect should be used)

class LogoutRedirectChooser

  def initialize(request_url)
    @url = request_url
  end

  def choose(default:)
    if url_indicates_concept_coach?
      URI.join(default, "?cc=1").to_s
    else
      default
    end
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
    ActiveRecord::Type::Boolean.new.cast(boolean_thing)
  end

end
