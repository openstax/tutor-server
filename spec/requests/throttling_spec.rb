require "rails_helper"

RSpec.describe "Throttles", type: :request, version: :v1 do

  context 'POST /api/log/entry' do
    let(:limit) { 50 }

    it 'allows requests under the limit, throttles at limit, and logs only once, all based on IP' do
      allow_any_instance_of(Rack::Attack::Request).to receive(:ip).and_return("1.2.3.4")

      # Allowed
      limit.times do
        api_post '/api/log/entry', nil
        expect(response).to_not have_http_status(429)
      end

      # First to pass the limit
      expect_any_instance_of(Rack::Attack::Request).to receive(:log_throttled!).once
      api_post '/api/log/entry', nil
      expect(response).to have_http_status(429)

      # Second to pass the limit
      api_post '/api/log/entry', nil
      expect(response).to have_http_status(429)

      allow_any_instance_of(Rack::Attack::Request).to receive(:ip).and_return("4.3.2.1")

      # Different IP OK
      api_post '/api/log/entry', nil
      expect(response).to_not have_http_status(429)
    end
  end

  context 'PUT /api/purchases/:id/check' do
    let(:limit) { 10 }

    it 'allows requests under the limit, throttles at limit, and logs only once, all based on ID' do
      # Allowed
      limit.times do
        api_put '/api/purchases/first_ID/check', nil
        expect(response).to_not have_http_status(429)
      end

      # First to pass the limit
      expect_any_instance_of(Rack::Attack::Request).to receive(:log_throttled!).once
      api_put '/api/purchases/first_ID/check', nil
      expect(response).to have_http_status(429)

      # Second to pass the limit
      api_put '/api/purchases/first_ID/check', nil
      expect(response).to have_http_status(429)

      # Different IP OK
      api_put '/api/purchases/second_ID/check', nil
      expect(response).to_not have_http_status(429)
    end
  end

end
