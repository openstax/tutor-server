require 'rails_helper'

RSpec.describe ApplicationController do
  let!(:controller) { ApplicationController.new }

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
      t = Time.now

      Settings.timecop_offset = nil
      controller.send :load_time
      expect(Time.now).to be_within(1.second).of(t)

      Settings.timecop_offset = 1.hour
      controller.send :load_time
      expect(Time.now).to be_within(1.second).of(t + 1.hour)

      Settings.timecop_offset = -1.hour
      controller.send :load_time
      expect(Time.now).to be_within(1.second).of(t - 1.hour)

      Settings.timecop_offset = nil
      controller.send :load_time
      expect(Time.now).to be_within(1.second).of(t)
    end
  end

  context 'with timecop disabled' do
    before(:all) do
      Rails.application.secrets[:timecop_enable] = false
    end

    it 'does not travel time' do
      t = Time.now

      Settings.timecop_offset = nil
      controller.send :load_time
      expect(Time.now).to be_within(1.second).of(t)

      Settings.timecop_offset = 1.hour
      controller.send :load_time
      expect(Time.now).to be_within(1.second).of(t)

      Settings.timecop_offset = -1.hour
      controller.send :load_time
      expect(Time.now).to be_within(1.second).of(t)

      Settings.timecop_offset = nil
      controller.send :load_time
      expect(Time.now).to be_within(1.second).of(t)
    end
  end
end
