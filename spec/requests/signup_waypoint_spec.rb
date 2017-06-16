require "rails_helper"

RSpec.describe "Signup waypoint", type: :request do

  it 'lets teachers signup' do
    get("/non_student_signup")

    expect(redirect_path).to eq "/dashboard"
    expect(redirect_query_hash).to include(block_sign_up: "false", straight_to_sign_up: "true")

    get(redirect_path_and_query)

    expect(redirect_path).to eq "/accounts/login"
    expect(redirect_query_hash).to include(go: "signup")
  end

  def redirect_path
    redirect_uri.path
  end

  def redirect_path_and_query
    "#{redirect_uri.path}?#{redirect_uri.query}"
  end

  def redirect_query_hash
    Rack::Utils.parse_nested_query(redirect_uri.query).symbolize_keys
  end

  def redirect_uri
    expect(response.code).to match "302|301"
    uri = URI.parse(response.headers["Location"])
  end

end
