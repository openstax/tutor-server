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

    it 'sets the X-App-Date header to the timecop time' do
      t = Time.now

      Settings.timecop_offset = nil
      controller.send :load_time
      controller.send :set_app_date_header
      header_time = Time.parse(controller.response.headers['X-App-Date'])
      expect(header_time).to be_within(1.second).of(t)

      Settings.timecop_offset = 1.hour
      controller.send :load_time
      controller.send :set_app_date_header
      header_time = Time.parse(controller.response.headers['X-App-Date'])
      expect(header_time).to be_within(1.second).of(t + 1.hour)

      Settings.timecop_offset = -1.hour
      controller.send :load_time
      controller.send :set_app_date_header
      header_time = Time.parse(controller.response.headers['X-App-Date'])
      expect(header_time).to be_within(1.second).of(t - 1.hour)

      Settings.timecop_offset = nil
      controller.send :load_time
      controller.send :set_app_date_header
      header_time = Time.parse(controller.response.headers['X-App-Date'])
      expect(header_time).to be_within(1.second).of(t)
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

    it 'sets the X-App-Date header to the actual time' do
      t = Time.now

      Settings.timecop_offset = nil
      controller.send :load_time
      controller.send :set_app_date_header
      header_time = Time.parse(controller.response.headers['X-App-Date'])
      expect(header_time).to be_within(1.second).of(t)

      Settings.timecop_offset = 1.hour
      controller.send :load_time
      controller.send :set_app_date_header
      header_time = Time.parse(controller.response.headers['X-App-Date'])
      expect(header_time).to be_within(1.second).of(t)

      Settings.timecop_offset = -1.hour
      controller.send :load_time
      controller.send :set_app_date_header
      header_time = Time.parse(controller.response.headers['X-App-Date'])
      expect(header_time).to be_within(1.second).of(t)

      Settings.timecop_offset = nil
      controller.send :load_time
      controller.send :set_app_date_header
      header_time = Time.parse(controller.response.headers['X-App-Date'])
      expect(header_time).to be_within(1.second).of(t)
    end
  end

  context 'rescue_from_exception' do
    let(:non_notifying_exception) {
      SecurityTransgression.new('Test Non-notifying').tap{ |ex| ex.set_backtrace([]) }
    }
    let(:notifying_exception)     {
      StandardError.new('Test Notifying').tap{ |ex| ex.set_backtrace([]) }
    }

    let(:oauth2_headers) { {} }
    let(:oauth2_status)  { 500 }
    let(:oauth2_body)    { '' }
    let(:oauth2_request) {
      OpenStruct.new(headers: oauth2_headers, status: oauth2_status, body: oauth2_body)
    }
    let(:oauth2_exception)     {
      OAuth2::Error.new(oauth2_request).tap{ |ex| ex.set_backtrace([]) }
    }

    let(:nested_exception)        {
      begin
        raise StandardError, 'Test Wrapped'
      rescue StandardError => exception
        begin
          raise StandardError, 'Test Wrapper 1', cause: exception
        rescue StandardError => exception
          begin
            raise StandardError, 'Test Wrapper 2', cause: exception
          rescue StandardError => exception
            exception
          end
        end
      end
    }

    let(:env) { {} }

    before(:each) do
      @request = controller.request
      controller.request = Hashie::Mash.new(env: env)
    end

    after(:each) do
      controller.request = @request
    end

    it 'sends exception emails for notifying exceptions' do
      expect(ExceptionNotifier).to receive(:notify_exception).once.with(
        notifying_exception,
        env: env,
        data: {
          error_id: a_kind_of(String),
          class: 'StandardError',
          message: 'Test Notifying',
          cause: nil,
          dns_name: 'unknown',
          extras: {}.inspect
        },
        sections: %w(data request session environment backtrace)
      )

      expect{ controller.send :rescue_from_exception, notifying_exception }
        .to raise_error(notifying_exception)
    end

    it 'does not send exception email for non-notifying exceptions' do
      expect(ExceptionNotifier).not_to receive(:notify_exception)

      expect{ controller.send :rescue_from_exception, non_notifying_exception }
        .to raise_error(non_notifying_exception)
    end

    it 'displays extra information from OAuth2::Errors' do
      expect(ExceptionNotifier).to receive(:notify_exception).once.with(
        oauth2_exception,
        env: env,
        data: {
          error_id: a_kind_of(String),
          class: 'OAuth2::Error',
          message: '',
          cause: nil,
          dns_name: 'unknown',
          extras: {
            headers: oauth2_headers,
            status: oauth2_status,
            body: oauth2_body
          }.inspect
        },
        sections: %w(data request session environment backtrace)
      )

      expect{ controller.send :rescue_from_exception, oauth2_exception }
        .to raise_error(oauth2_exception)
    end

    it 'displays nested exceptions' do
      expect(ExceptionNotifier).to receive(:notify_exception).once.with(
        nested_exception,
        env: env,
        data: {
          error_id: a_kind_of(String),
          class: 'StandardError',
          message: 'Test Wrapper 2',
          cause: {
            class: 'StandardError',
            message: 'Test Wrapper 1',
            cause: {
              class: 'StandardError',
              message: 'Test Wrapped',
              cause: nil
            }
          },
          dns_name: 'unknown',
          extras: {}.inspect
        },
        sections: %w(data request session environment backtrace)
      )

      expect{ controller.send :rescue_from_exception, nested_exception }
        .to raise_error(nested_exception)
    end
  end
end
