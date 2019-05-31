require 'rails_helper'

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
  context 'rescuing exceptions' do
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
end
