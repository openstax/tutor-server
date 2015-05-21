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

    it 'freezes time' do
      t = Time.now

      Settings.timecop_time = t
      controller.send :load_time
      expect(Time.now).to eq t

      Settings.timecop_time = nil
      controller.send :load_time
      expect(Time.now).to be > t
    end
  end

  context 'with timecop disabled' do
    before(:all) do
      Rails.application.secrets[:timecop_enable] = false
    end

    it 'does not freeze time' do
      t = Time.now

      Settings.timecop_time = t
      controller.send :load_time
      expect(Time.now).to be > t

      Settings.timecop_time = nil
      controller.send :load_time
      expect(Time.now).to be > t
    end
  end
end
