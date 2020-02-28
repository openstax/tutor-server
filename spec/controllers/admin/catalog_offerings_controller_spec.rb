require 'rails_helper'

RSpec.describe Admin::CatalogOfferingsController, type: :controller do
  let(:admin)       do
    FactoryBot.create :user_profile, :administrator, username: 'admin', full_name: 'Administrator'
  end
  let(:offering)    { FactoryBot.create(:catalog_offering) }
  let!(:attributes) { offering.attributes }

  before { controller.sign_in(admin) }

  context '#index' do
    it 'displays offerings' do
      get :index
      expect(response).to have_http_status(:success)
    end
  end

  context '#create' do
    before { offering.destroy }

    it 'complains about blank fields' do
      expect do
        post :create, params: { offering: attributes.except('description') }
      end.to_not change(Catalog::Models::Offering, :count)
      expect(controller).to set_flash.now[:error].to(/Description can\'t be blank/)
    end

    it 'can create an offering' do
      expect do
        post :create, params: { offering: attributes }
      end.to change(Catalog::Models::Offering, :count).by(1)
      expect(response).to redirect_to action: :index
    end

    it 'can have duplicated sf book names' do
      FactoryBot.create(:catalog_offering, salesforce_book_name: "Blah")
      attributes["salesforce_book_name"] = "Blah"

      expect do
        post :create, params: { offering: attributes }
      end.to change(Catalog::Models::Offering, :count).by(1)
      expect(response).to redirect_to action: :index
    end
  end

  context '#update' do
    it 'complains about blank fields' do
      attrs = attributes.dup
      attrs['webview_url'] = ''

      expect do
        put :update, params: { id: offering.id, offering: attrs }
      end.to_not change(Catalog::Models::Offering, :count)
      expect(controller).to set_flash.now[:error].to(/Webview url can\'t be blank/)
    end

    it 'can update an offering' do
      expect(offering.is_tutor).to be false
      expect(offering.is_concept_coach).to be false
      expect(offering.does_cost).to be false
      response = put :update, params: {
        id: offering.id,
        offering: offering.attributes.merge(
          'is_tutor' => 't',
          'is_concept_coach' => 't',
          'does_cost' => 't'
        )
      }
      expect(response).to redirect_to action: :index
      offering.reload
      expect(offering.is_tutor).to be true
      expect(offering.is_concept_coach).to be true
      expect(offering.does_cost).to be true
    end
  end

  context '#destroy' do
    it 'can delete an offering' do
      expect do
        delete :destroy, params: { id: offering.id }
      end.to change { Catalog::Models::Offering.count }.by(-1)
      expect { offering.reload }.to raise_error(ActiveRecord::RecordNotFound)
      expect(response).to redirect_to action: :index
    end

    it 'does not delete the offering if it has courses' do
      FactoryBot.create :course_profile_course, offering: offering

      expect do
        delete :destroy, params: { id: offering.id }
      end.not_to change { Catalog::Models::Offering.count }
      expect { offering.reload }.not_to raise_error
    end
  end
end
