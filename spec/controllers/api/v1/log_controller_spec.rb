require "rails_helper"

RSpec.describe Api::V1::LogController, type: :controller, api: true, version: :v1 do

  describe "#entry" do

    it 'requires a level' do
      expect(Rails.logger).not_to receive(:log)
      log(message: 'hi')
      expect(response.body_as_hash).to eq({status: 422, errors: [{code: "level_missing",
                                                                  message: "Level missing"}]})
    end

    it 'requires a valid level' do
      expect(Rails.logger).not_to receive(:log)
      log(level: 'blah', message: 'hi')
      expect(response.body_as_hash).to eq({status: 422, errors: [{code: "bad_level",
                                                                  message: "Bad level"}]})
    end


    it 'requires a message' do
      expect(Rails.logger).not_to receive(:log)
      log(level: 'info', message: '')
      expect(response.body_as_hash).to eq({status: 422, errors: [{code: "message_missing",
                                                                  message: "Message missing"}]})
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
      log(entries: [{level: 'info', message: 'hi'}, {level: 'warn', message: 'take care!'}])
      expect(response).to have_http_status(:created)
    end

  end


  describe '#track' do
    let(:user) { FactoryGirl.create(:user) }
    let(:user_token)   { FactoryGirl.create :doorkeeper_access_token,
                                            resource_owner_id: user.id }

    it 'rejects student access' do
      user.account.update_attributes(role: :student)
      expect(TrackTutorOnboardingEvent).not_to receive(:perform_later)
      expect {
        api_post :onboarding_event, user_token, parameters: { code: 'arrived_my_courses' }
      }.to raise_error(SecurityTransgression)
    end

    describe 'as an instructor' do
      before(:each) { user.account.role = :instructor }

      it 'rejects invalid codes' do
        expect(TrackTutorOnboardingEvent).not_to receive(:perform_later)
        expect {
          api_post :onboarding_event, user_token, parameters: { code: 'bad&wrong' }
        }.to raise_error(SecurityTransgression)
      end

      it 'tracks valid codes' do
        user.account.update_attributes!(role: :instructor)
        expect(TrackTutorOnboardingEvent).to receive(:perform_later).with(
                                               data: { decision: "I won't be using it" },
                                               event: 'made_adoption_decision',
                                               user: anything,
                                             )
        api_post :onboarding_event, user_token, parameters: {
                   code: 'made_adoption_decision', data: { decision: "I won't be using it" },
                 }
        expect(response).to have_http_status(:success)
      end
    end
  end

  def log(options)
    api_post :entry, nil, raw_post_data: options.to_json
  end

end
