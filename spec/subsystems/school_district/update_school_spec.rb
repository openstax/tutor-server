require 'rails_helper'

RSpec.describe SchoolDistrict::UpdateSchool do
  let(:school) { FactoryBot.create(:school_district_school, name: 'Cool school') }
  let(:district) { FactoryBot.create(:school_district_district, name: 'Wow great district') }

  it 'updates course attributes' do
    described_class[school: school, name: 'Not cool', district: district]

    expect(school.reload.name).to eq('Not cool')
    expect(school.district_name).to eq('Wow great district')
  end
end
