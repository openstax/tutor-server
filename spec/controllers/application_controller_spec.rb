require 'rails_helper'

RSpec.describe ApplicationController, type: :controller do
  subject(:controller) {
    cc = ApplicationController.new
    cc.response = ActionController::TestResponse.new
    cc
  }

  before(:all) do
    @timecop_enable = Rails.application.secrets[:timecop_enable]
  end

  after(:all) do
    Rails.application.secrets[:timecop_enable] = @timecop_enable
  end

  context 'with timecop enabled' do
    before(:all) do
      Rails.application.secrets[:timecop_enable] = true
    end

    it 'travels time' do
      t = Time.current

      Settings::Timecop.offset = nil
      controller.send :load_time
      expect(Time.current).to be_within(1).of(t)

      Settings::Timecop.offset = 1.hour
      controller.send :load_time
      expect(Time.current).to be_within(1).of(t + 1.hour)

      Settings::Timecop.offset = -1.hour
      controller.send :load_time
      expect(Time.current).to be_within(1).of(t - 1.hour)

      Settings::Timecop.offset = nil
      controller.send :load_time
      expect(Time.current).to be_within(1).of(t)
    end

    it 'sets the X-App-Date header to the timecop time' do
      t = Time.current

      Settings::Timecop.offset = nil
      controller.send :load_time
      controller.send :set_app_date_header
      header_time = Time.parse(controller.response.headers['X-App-Date'])
      expect(header_time).to be_within(1).of(t)

      Settings::Timecop.offset = 1.hour
      controller.send :load_time
      controller.send :set_app_date_header
      header_time = Time.parse(controller.response.headers['X-App-Date'])
      expect(header_time).to be_within(1).of(t + 1.hour)

      Settings::Timecop.offset = -1.hour
      controller.send :load_time
      controller.send :set_app_date_header
      header_time = Time.parse(controller.response.headers['X-App-Date'])
      expect(header_time).to be_within(1).of(t - 1.hour)

      Settings::Timecop.offset = nil
      controller.send :load_time
      controller.send :set_app_date_header
      header_time = Time.parse(controller.response.headers['X-App-Date'])
      expect(header_time).to be_within(1).of(t)
    end
  end

  context 'with timecop disabled' do
    before(:all) do
      Rails.application.secrets[:timecop_enable] = false
    end

    it 'does not travel time' do
      t = Time.current

      Settings::Timecop.offset = nil
      controller.send :load_time
      expect(Time.current).to be_within(1).of(t)

      Settings::Timecop.offset = 1.hour
      controller.send :load_time
      expect(Time.current).to be_within(1).of(t)

      Settings::Timecop.offset = -1.hour
      controller.send :load_time
      expect(Time.current).to be_within(1).of(t)

      Settings::Timecop.offset = nil
      controller.send :load_time
      expect(Time.current).to be_within(1).of(t)
    end

    it 'sets the X-App-Date header to the actual time' do
      t = Time.current

      Settings::Timecop.offset = nil
      controller.send :load_time
      controller.send :set_app_date_header
      header_time = Time.parse(controller.response.headers['X-App-Date'])
      expect(header_time).to be_within(1).of(t)

      Settings::Timecop.offset = 1.hour
      controller.send :load_time
      controller.send :set_app_date_header
      header_time = Time.parse(controller.response.headers['X-App-Date'])
      expect(header_time).to be_within(1).of(t)

      Settings::Timecop.offset = -1.hour
      controller.send :load_time
      controller.send :set_app_date_header
      header_time = Time.parse(controller.response.headers['X-App-Date'])
      expect(header_time).to be_within(1).of(t)

      Settings::Timecop.offset = nil
      controller.send :load_time
      controller.send :set_app_date_header
      header_time = Time.parse(controller.response.headers['X-App-Date'])
      expect(header_time).to be_within(1).of(t)
    end
  end
end
