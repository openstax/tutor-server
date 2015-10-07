require 'rails_helper'

class TestExceptionsController < ApplicationController
  skip_before_filter :authenticate_user!

  def bad_action
    RaiseUnknownConstantException
  end
end

RSpec.describe TestExceptionsController, type: :controller do
  context 'rescuing exceptions' do
    it 'fires off an email' do
      ActionMailer::Base.deliveries.clear

      allow(request).to receive(:remote_ip) { '96.21.0.39' }

      expect { get :bad_action }.to raise_error(NameError)
      expect(ActionMailer::Base.deliveries.size).to eq(1)
    end
  end
end
