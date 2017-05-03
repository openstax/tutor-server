require 'rails_helper'

RSpec.describe Admin::CatalogOfferingsController, type: :controller do
  let(:admin) do
    profile = FactoryGirl.create :user_profile,
                                 :administrator,
                                 username: 'admin',
                                 full_name: 'Administrator'
    strategy = User::Strategies::Direct::User.new(profile)
    User::User.new(strategy: strategy)
  end
  let(:offering)   { FactoryGirl.create(:catalog_offering) }
  let(:attributes) { FactoryGirl.build(:catalog_offering).attributes }

  before {
    controller.sign_in(admin)
  }

  it 'displays offerings' do
    get :index
    expect(response).to have_http_status(:success)
  end

  describe 'Creating an offering' do
    let(:attributes) { FactoryGirl.build(:catalog_offering).attributes }

    it 'complains about blank fields' do
      expect{
        post :create, { offering: attributes.except('description') }
        expect(controller).to set_flash[:error].to(/Description can\'t be blank/).now
      }.to_not change(Catalog::Models::Offering, :count)
    end

    it 'can create offering' do
      expect{
        response = post :create, { offering: attributes }
        expect(response).to redirect_to action: 'index'
      }.to change(Catalog::Models::Offering, :count).by(1)
    end

    it 'can have duplicated sf book names' do
      FactoryGirl.create(:catalog_offering, salesforce_book_name: "Blah")
      attributes["salesforce_book_name"] = "Blah"
      expect{
        response = post :create, { offering: attributes }
        expect(response).to redirect_to action: 'index'
      }.to change(Catalog::Models::Offering, :count).by(1)
    end
  end

  describe 'Editing an offering' do
    it 'complains about blank fields' do
      attrs = offering.attributes
      attrs['webview_url']=''
      expect{
        put :update, { id: offering.id, offering: attrs }
        expect(controller).to set_flash[:error].to(/Webview url can\'t be blank/).now
      }.to_not change(Catalog::Models::Offering, :count)
    end

    it 'can update an offering' do
      expect(offering.is_tutor).to be false
      expect(offering.is_concept_coach).to be false
      expect(offering.does_cost).to be false
      response = put :update, { id: offering.id,
                       offering: offering.attributes.merge({'is_tutor' => 't', 'is_concept_coach' => 't', 'does_cost' => 't' }) }
      expect(response).to redirect_to action: 'index'
      offering.reload
      expect(offering.is_tutor).to be true
      expect(offering.is_concept_coach).to be true
      expect(offering.does_cost).to be true
    end
  end


end
