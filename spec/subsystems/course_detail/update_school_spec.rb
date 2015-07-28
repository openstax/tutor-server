require 'rails_helper'

RSpec.describe CourseDetail::UpdateSchool do
  let(:school) { FactoryGirl.create(:school, name: 'Cool school') }
  let(:district) { FactoryGirl.create(:district, name: 'Wow great district') }

  it 'updates course attributes' do
    described_class[id: school.id,
                    attributes: { name: 'Not cool',
                                  course_detail_district_id: district.id }]

    expect(school.reload.name).to eq('Not cool')
    expect(school.district_name).to eq('Wow great district')
  end

  it 'bars against bad webform input' do
    expect {
      described_class[id: school.id, attributes: { name: 'Not cool',
                                                   course_detail_district_id: '0' }]

      described_class[id: school.id, attributes: { name: 'Not cool',
                                                   course_detail_district_id: 0 }]
    }.not_to raise_error
  end
end
