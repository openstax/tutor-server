require 'rails_helper'

RSpec.describe "Terms", type: :request, api: true, version: :v1 do

  let(:application)     { FactoryBot.create :doorkeeper_application }
  let!(:user_1)         { FactoryBot.create(:user) }
  let(:user_1_token)    { FactoryBot.create :doorkeeper_access_token,
                                              application: application,
                                              resource_owner_id: user_1.id }

  let!(:general_terms_of_use) { create_contract!('general_terms_of_use') }
  let!(:privacy_policy) { create_contract!('privacy_policy') }

  context 'getting contract list' do
    it 'returns contract info for a user' do
      api_get('/api/terms', user_1_token)

      expect(response.body_as_hash).to match a_collection_containing_exactly(
        a_hash_including(
          name: 'general_terms_of_use',
          title: 'general_terms_of_use title',
          content: 'general_terms_of_use content',
          version: 1,
          is_signed: false,
          has_signed_before: false,
          is_proxy_signed: false
        ),
        a_hash_including(
          name: 'privacy_policy',
          title: 'privacy_policy title',
          content: 'privacy_policy content',
          version: 1,
          is_signed: false,
          has_signed_before: false,
          is_proxy_signed: false
        )
      )
    end
  end

  context 'signing terms' do
    it 'lets users sign one set of terms' do
      expect(FinePrint.signed_contract?(user_1.to_model, general_terms_of_use)).to be false

      api_put("/api/terms/#{general_terms_of_use.id}", user_1_token)

      expect(response).to have_http_status(:success)
      expect(FinePrint.signed_contract?(user_1.to_model, general_terms_of_use)).to be true
    end

    it 'lets users sign multiple terms' do
      expect(FinePrint.signed_contract?(user_1.to_model, general_terms_of_use)).to be false
      expect(FinePrint.signed_contract?(user_1.to_model, privacy_policy)).to be false

      api_put("/api/terms/#{general_terms_of_use.id},#{privacy_policy.id}", user_1_token)

      expect(response).to have_http_status(:success)
      expect(FinePrint.signed_contract?(user_1.to_model, general_terms_of_use)).to be true
      expect(FinePrint.signed_contract?(user_1.to_model, privacy_policy)).to be true
    end

    it 'errors if terms do not exist' do
      api_put("/api/terms/jjj", user_1_token)
      expect(response).to have_http_status(:unprocessable_entity)
    end

    it 'does not error if one of terms already signed' do
      expect(FinePrint.signed_contract?(user_1.to_model, privacy_policy)).to be false
      FinePrint.sign_contract(user_1.to_model, 'general_terms_of_use')
      expect{
        api_put("/api/terms/#{general_terms_of_use.id},#{privacy_policy.id}", user_1_token)
      }.to change{FinePrint::Signature.count}.by(1)
      expect(response).to have_http_status(:success)
      expect(FinePrint.signed_contract?(user_1.to_model, privacy_policy)).to be true
    end
  end



end
