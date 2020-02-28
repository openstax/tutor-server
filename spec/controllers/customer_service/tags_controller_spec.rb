require 'rails_helper'

RSpec.describe CustomerService::TagsController, type: :controller do
  let(:customer_service) { FactoryBot.create(:user_profile, :customer_service) }
  let!(:tag_1) { FactoryBot.create :content_tag, value: 'k12phys-ch04-ex003' }
  let!(:tag_2) { FactoryBot.create :content_tag, value: 'k12phys-ch04-s03-lo01' }
  let!(:tag_3) { FactoryBot.create :content_tag, value: 'ost-tag-teks-112-39-c-4d' }

  before { controller.sign_in(customer_service) }

  context 'GET #index' do
    it 'does not list tags' do
      get :index
      expect(assigns[:tags]).to be_nil
    end

    it 'returns a list of tags that matches tag value' do
      get :index, params: { query: 'k12phys' }

      expect(assigns[:tags].order(:id)).to eq [tag_1, tag_2]
    end

    it 'returns nothing if there are no matches' do
      get :index, params: { query: 'time-short' }

      expect(assigns[:tags]).to eq []
    end
  end

  context 'disallowing baddies' do
    it 'disallows unauthenticated visitors' do
      allow(controller).to receive(:current_account) { nil }
      allow(controller).to receive(:current_user) { nil }

      get :index
      expect(response).not_to be_successful
    end

    it 'disallows non-customer-service authenticated visitors' do
      controller.sign_in(FactoryBot.create(:user_profile))

      expect { get :index }.to raise_error(SecurityTransgression)
    end
  end
end
