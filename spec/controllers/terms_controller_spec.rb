require 'rails_helper'

RSpec.describe TermsController, type: :controller do
  let(:contract) do
    FinePrint::Contract.create!(
      name: 'general_terms_of_use',
      title: 'General Terms of Use',
      content: Faker::Lorem.paragraphs,
      version: 10
    )
  end
  let(:new_user) { FactoryBot.create(:user_profile, skip_terms_agreement: true) }

  context 'terms of service' do

    context "as a signed in new user" do
      render_views

      it 'can agree to terms' do
        controller.sign_in new_user
        post :agree, params: { i_agree: '1', contract_id: contract.id }
        expect(response).to have_http_status(:redirect)
        expect(
          FinePrint.signed_contract?(new_user, contract)
        ).to eq true
      end
    end
  end
end
