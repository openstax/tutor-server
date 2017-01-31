require 'rails_helper'

class TestExceptionsController < ApplicationController
  skip_before_filter :authenticate_user!

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

    it 'fires off an email for some error' do
      expect { get :bad_action }.to raise_error(NameError)
      expect(ActionMailer::Base.deliveries.size).to eq(1)
    end

    it 'fires off an email for a UrlGenerationError' do
      expect { get :url_generation_error }.to raise_error(ActionController::UrlGenerationError)
      expect(ActionMailer::Base.deliveries.size).to eq(1)
    end
  end
end
