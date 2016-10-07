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

  end

  def log(options)
    api_post :entry, nil, raw_post_data: options.to_json
  end

end
