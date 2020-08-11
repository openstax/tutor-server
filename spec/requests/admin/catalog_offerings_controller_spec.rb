require 'rails_helper'

RSpec.describe Admin::CatalogOfferingsController, type: :request do
  let(:admin)       do
    FactoryBot.create :user_profile, :administrator, username: 'admin', full_name: 'Administrator'
  end
  let(:offering)    { FactoryBot.create(:catalog_offering) }
  let!(:attributes) { offering.attributes.except('id') }

  before { sign_in! admin }

  context '#index' do
    it 'displays offerings' do
      get admin_catalog_offerings_url
      expect(response).to have_http_status(:success)
    end
  end

  context '#create' do
    before { offering.destroy }

    it 'complains about blank fields' do
      expect do
        post admin_catalog_offerings_url, params: { offering: attributes.except('description') }
      end.to_not change(Catalog::Models::Offering, :count)
      expect(flash.now[:error]).to eq("Description can't be blank")
    end

    it 'can create an offering and set its attributes' do
      expect do
        post admin_catalog_offerings_url, params: { offering: attributes }
      end.to change(Catalog::Models::Offering, :count).by(1)
      expect(response).to redirect_to action: :index

      offering = Catalog::Models::Offering.order(:created_at).last
      expect(offering.is_preview_available).to eq true
      expect(offering.is_available).to eq true
      expect(offering.is_tutor).to eq true
      expect(offering.is_concept_coach).to eq false
      expect(offering.does_cost).to eq false
    end

    it 'can have duplicated sf book names' do
      FactoryBot.create(:catalog_offering, salesforce_book_name: "Blah")
      attributes["salesforce_book_name"] = "Blah"

      expect do
        post admin_catalog_offerings_url, params: { offering: attributes }
      end.to change(Catalog::Models::Offering, :count).by(1)
      expect(response).to redirect_to action: :index
    end
  end

  context '#update' do
    it 'complains about blank fields' do
      attrs = attributes.dup
      attrs['webview_url'] = ''

      expect do
        put admin_catalog_offering_url(offering.id), params: { offering: attrs }
      end.to_not change(Catalog::Models::Offering, :count)
      expect(flash.now[:error]).to eq("Webview url can't be blank")
    end

    it 'can update an offering' do
      expect(offering.is_preview_available).to eq true
      expect(offering.is_available).to eq true
      expect(offering.is_tutor).to eq true
      expect(offering.is_concept_coach).to eq false
      expect(offering.does_cost).to eq false

      response = put admin_catalog_offering_url(offering.id), params: {
        offering: offering.attributes.merge(
          {
            is_preview_available: false,
            is_available: false,
            is_tutor: false,
            is_concept_coach: true,
            does_cost: true
          }.stringify_keys
        )
      }
      expect(response).to redirect_to action: :index

      offering.reload
      expect(offering.is_preview_available).to eq false
      expect(offering.is_available).to eq false
      expect(offering.is_tutor).to eq false
      expect(offering.is_concept_coach).to eq true
      expect(offering.does_cost).to eq true
    end
  end

  context '#destroy' do
    it 'soft-deletes the offering' do
      expect do
        delete admin_catalog_offering_url(offering.id)
      end.to  not_change { Catalog::Models::Offering.count }
         .and change     { offering.reload.deleted_at }.from(nil)
      expect(response).to redirect_to action: :index
    end

    it 'does nothing if the offering is already deleted' do
      FactoryBot.create :course_profile_course, offering: offering

      offering.destroy!

      expect do
        delete admin_catalog_offering_url(offering.id)
      end.to  not_change { Catalog::Models::Offering.count }
         .and not_change { offering.reload.deleted_at }
      expect(response).to be_ok
    end
  end

  context '#restore' do
    it 'can restore a deleted offering' do
      offering.destroy!

      expect do
        put restore_admin_catalog_offering_url(offering.id)
      end.to  not_change { Catalog::Models::Offering.count }
         .and change     { offering.reload.deleted_at }.to(nil)
      expect(response).to redirect_to action: :index
    end
  end
end
