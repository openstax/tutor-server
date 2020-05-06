require 'rails_helper'

RSpec.describe ApplicationController, type: :controller do
  subject(:controller) do
    Class.new(described_class) do
      skip_before_action :authenticate_user!
    end.new.tap do |controller|
      controller.request = request
      controller.response = response
    end
  end

  context 'callbacks' do
    subject do |&block|
      controller.run_callbacks(:process_action, &block)
      @response = controller.response
    end
    let(:current_time)   { Time.current }

    context 'with no X-App-Date header in the request' do
      context 'not in real production' do
        before { expect(IAm.real_production?).to eq false }

        it "does not modify the server's time" do
          expect(Time.current).to be_within(1).of current_time
          subject { expect(Time.current).to be_within(1).of current_time }
          expect(Time.current).to be_within(1).of current_time
        end

        it "sets the response's X-App-Date header to the actual time" do
          subject

          expect(Time.parse(response.headers['X-App-Date'])).to be_within(1).of current_time
        end
      end

      context 'in real production' do
        before { expect(IAm).to receive(:real_production?).and_return(true) }

        it "does not modify the server's time" do
          expect(Time.current).to be_within(1).of current_time
          subject { expect(Time.current).to be_within(1).of current_time }
          expect(Time.current).to be_within(1).of current_time
        end

        it "sets the response's X-App-Date header to the actual time" do
          subject

          expect(Time.parse(response.headers['X-App-Date'])).to be_within(1).of current_time
        end
      end
    end

    context 'with a valid X-App-Date header in the request' do
      let(:max_time_delta) { 100000000 }
      let(:time)           { current_time + rand(max_time_delta) - max_time_delta/2 }
      before               { request.headers['X-App-Date'] = time.httpdate }

      context 'not in real production' do
        before { expect(IAm.real_production?).to eq false }

        it "sets the server's time to the request's X-App-Date header" do
          expect(Time.current).to be_within(1).of current_time
          subject { expect(Time.current).to be_within(1).of time }
          expect(Time.current).to be_within(1).of current_time
        end

        it "sets the response's X-App-Date header based on the request header" do
          subject

          expect(response).to have_http_status :ok
          expect(Time.parse(response.headers['X-App-Date'])).to be_within(1).of time
        end
      end

      context 'in real production' do
        before { expect(IAm).to receive(:real_production?).and_return(true) }

        it "does not modify the server's time" do
          expect(Time.current).to be_within(1).of current_time
          subject { expect(Time.current).to be_within(1).of current_time }
          expect(Time.current).to be_within(1).of current_time
        end

        it "sets the response's X-App-Date header to the actual time" do
          subject

          expect(Time.parse(response.headers['X-App-Date'])).to be_within(1).of current_time
        end
      end
    end

    context 'with an invalid X-App-Date header in the request' do
      before { request.headers['X-App-Date'] = 'Yesterday' }

      context 'not in real production' do
        before { expect(IAm.real_production?).to eq false }

        it "does not modify the server's time" do
          expect(Time.current).to be_within(1).of current_time
          subject { expect(Time.current).to be_within(1).of current_time }
          expect(Time.current).to be_within(1).of current_time
        end

        it "returns 400 Bad Request and sets the response's X-App-Date header to the actual time" do
          subject

          expect(response).to have_http_status :bad_request
          expect(response.body).to include('Invalid X-App-Date header')
          expect(Time.parse(response.headers['X-App-Date'])).to be_within(1).of current_time
        end
      end

      context 'in real production' do
        before { expect(IAm).to receive(:real_production?).and_return(true) }

        it "does not modify the server's time" do
          expect(Time.current).to be_within(1).of current_time
          subject { expect(Time.current).to be_within(1).of current_time }
          expect(Time.current).to be_within(1).of current_time
        end

        it "sets the response's X-App-Date header to the actual time" do
          subject

          expect(Time.parse(response.headers['X-App-Date'])).to be_within(1).of current_time
        end
      end
    end
  end
end

class TestExceptionsController < ApplicationController
  skip_before_action :authenticate_user!

  def bad_action
    RaiseUnknownConstantException
  end

  def url_generation_error
    raise ActionController::UrlGenerationError
  end
end

RSpec.describe TestExceptionsController, type: :controller do
  before(:each) do
    ActionMailer::Base.deliveries.clear
    allow(request).to receive(:remote_ip) { '96.21.0.39' }
  end

  it 'notifies sentry for some error' do
    expect(Raven).to receive(:capture_exception) do |exception, *args|
      expect(exception).to be_a(NameError)
    end
    expect { get :bad_action }.to raise_error(NameError)
                              .and not_change { ActionMailer::Base.deliveries.size }
  end

  it 'notifies sentry for a UrlGenerationError' do
    expect(Raven).to receive(:capture_exception) do |exception, *args|
      expect(exception).to be_a(ActionController::UrlGenerationError)
    end
    expect { get :url_generation_error }.to raise_error(ActionController::UrlGenerationError)
                                        .and not_change { ActionMailer::Base.deliveries.size }
  end
end
