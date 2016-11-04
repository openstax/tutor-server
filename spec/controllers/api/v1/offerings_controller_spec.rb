require 'rails_helper'

RSpec.describe Api::V1::OfferingsController, type: :controller, api: true, version: :v1 do

  let!(:available_offering)           { FactoryGirl.create :catalog_offering }
  let!(:unavailable_offering)         { FactoryGirl.create :catalog_offering, is_available: false }

  let(:anon)                          { User::User.anonymous }
  let(:verified_faculty)              do
    FactoryGirl.create(:user).tap do |vf|
      vf.account.update_attribute :faculty_status, :confirmed_faculty
    end
  end
  let(:verified_faculty_access_token) do
    FactoryGirl.create :doorkeeper_access_token, resource_owner_id: verified_faculty.id
  end

  context '#index' do
    it 'delegates permission checking to the OfferingAccessPolicy' do
      expect(OfferingAccessPolicy).to(
        receive(:action_allowed?).with(:index, anon, Catalog::Models::Offering).and_return(false)
      )
      expect{ api_get :index, nil }.to raise_error(SecurityTransgression)
    end

    it 'lists all available offerings for verified faculty' do
      api_get :index, verified_faculty_access_token
      items = response.body_as_hash[:items].map(&:deep_stringify_keys)
      expect(items).to include Api::V1::OfferingRepresenter.new(available_offering).as_json
      expect(items).not_to include Api::V1::OfferingRepresenter.new(unavailable_offering).as_json
    end
  end

end
