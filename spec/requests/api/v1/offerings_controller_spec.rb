require 'rails_helper'

RSpec.describe Api::V1::OfferingsController, type: :request, api: true, version: :v1 do
  let!(:available_offering_1) { FactoryBot.create :catalog_offering, number: 2 }
  let!(:available_offering_2) { FactoryBot.create :catalog_offering, number: 1 }
  let!(:unavailable_preview)  { FactoryBot.create :catalog_offering, is_preview_available: false }
  let!(:unavailable_offering) { FactoryBot.create :catalog_offering, is_available: false }

  let(:anon)                  { User::Models::Profile.anonymous }
  let(:faculty)               do
    FactoryBot.create(:user_profile).tap do |user|
      user.account.confirmed_faculty!
      user.account.college!
    end
  end
  let(:faculty_access_token)  do
    FactoryBot.create :doorkeeper_access_token, resource_owner_id: faculty.id
  end

  context '#index' do
    it 'delegates permission checking to the OfferingAccessPolicy' do
      expect(OfferingAccessPolicy).to(
        receive(:action_allowed?).with(:index, anon, Catalog::Models::Offering).and_return(false)
      )
      expect { api_get api_offerings_url, nil }.to raise_error(SecurityTransgression)
    end

    it 'lists all offerings for verified college faculty, in order' do
      api_get api_offerings_url, faculty_access_token
      items = response.body_as_hash[:items].map(&:deep_stringify_keys)
      expect(items).to eq [
        Api::V1::OfferingRepresenter.new(available_offering_2).as_json,
        Api::V1::OfferingRepresenter.new(available_offering_1).as_json,
        Api::V1::OfferingRepresenter.new(unavailable_preview).as_json,
        Api::V1::OfferingRepresenter.new(unavailable_offering).as_json
      ]
    end
  end
end
