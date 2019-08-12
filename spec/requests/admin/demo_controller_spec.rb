require 'rails_helper'

RSpec.describe Admin::DemoController, type: :request do
  let(:admin) { FactoryBot.create :user_profile, :administrator }

  before { stub_current_user admin }

  [ :users, :import, :course, :assign, :work, :all ].each do |method|
    context "##{method}" do
      it 'works' do
        get send("admin_demo_#{method}_url")

        expect(response).to have_http_status(:ok)
      end
    end
  end
end
