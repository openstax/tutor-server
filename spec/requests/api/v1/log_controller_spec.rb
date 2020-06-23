require "rails_helper"

RSpec.describe Api::V1::LogController, type: :request, api: true, version: :v1 do
  context '#entry' do
    let(:limit) { 50 }

    it 'requires a level' do
      expect(Rails.logger).not_to receive(:log)
      log(message: 'hi')
      expect(response.body_as_hash).to eq(
        status: 422, errors: [ { code: "level_missing", message: "Level missing" } ]
      )
    end

    it 'requires a valid level' do
      expect(Rails.logger).not_to receive(:log)
      log(level: 'blah', message: 'hi')
      expect(response.body_as_hash).to eq(
        status: 422, errors: [ { code: "bad_level", message: "Bad level" } ]
      )
    end

    it 'requires a message' do
      expect(Rails.logger).not_to receive(:log)
      log(level: 'info', message: '')
      expect(response.body_as_hash).to eq(
        status: 422, errors: [ { code: "message_missing", message: "Message missing" } ]
      )
    end

    described_class::LOG_LEVELS.each do |string, enum|
      it "logs #{string}" do
        expect(Rails.logger).to receive(:log).with(enum, '(ext) hi')
        log(level: string, message: 'hi')
        expect(response).to have_http_status(:created)
      end
    end

    it 'does not care about level case' do
      expect(Rails.logger).to receive(:log).with(Logger::INFO, '(ext) hi')
      log(level: 'InFO', message: 'hi')
      expect(response).to have_http_status(:created)
    end

    it 'can log an array of entries' do
      expect(Rails.logger).to receive(:log).with(Logger::INFO, '(ext) hi')
      expect(Rails.logger).to receive(:log).with(Logger::WARN, '(ext) take care!')
      log(entries: [ { level: 'info', message: 'hi' }, { level: 'warn', message: 'take care!' } ])
      expect(response).to have_http_status(:created)
    end

    it 'allows requests under the limit, throttles at limit, and logs only once, all based on IP' do
      allow_any_instance_of(Rack::Attack::Request).to receive(:ip).and_return('1.2.3.4')

      # Allowed
      limit.times do
        api_post api_log_entry_url, nil
        expect(response).to_not have_http_status(429)
      end

      # First to pass the limit
      expect_any_instance_of(Rack::Attack::Request).to receive(:log_throttled!).once
      api_post api_log_entry_url, nil
      expect(response).to have_http_status(429)

      # Second to pass the limit
      api_post api_log_entry_url, nil
      expect(response).to have_http_status(429)

      allow_any_instance_of(Rack::Attack::Request).to receive(:ip).and_return('4.3.2.1')

      # Different IP OK
      api_post api_log_entry_url, nil
      expect(response).to_not have_http_status(429)
    end
  end

  context '#track' do
    let(:user) { FactoryBot.create(:user_profile) }
    let(:user_token)   { FactoryBot.create :doorkeeper_access_token, resource_owner_id: user.id }

    it 'rejects student access' do
      user.account.update_attributes(role: :student)
      expect(TrackTutorOnboardingEvent).not_to receive(:perform_later)
      expect {
        api_post api_log_url('arrived_my_courses'), user_token
      }.to raise_error(SecurityTransgression)
    end

    context 'as an instructor' do
      before(:each) { user.account.role = :instructor }

      it 'rejects invalid codes' do
        expect(TrackTutorOnboardingEvent).not_to receive(:perform_later)
        expect {
          api_post api_log_url('bad&wrong'), user_token
        }.to raise_error(SecurityTransgression)
      end

      it 'tracks valid codes' do
        user.account.update_attributes!(role: :instructor)
        expect(TrackTutorOnboardingEvent).to receive(:perform_later).with(
                                               data: { decision: "I won't be using it" },
                                               event: 'made_adoption_decision',
                                               user: anything,
                                             )
        api_post api_log_url('made_adoption_decision'), user_token, params: {
          data: { decision: "I won't be using it" },
        }.to_json
        expect(response).to have_http_status(:success)
      end
    end
  end

  def log(options)
    api_post api_log_entry_url, nil, params: options.to_json
  end
end
