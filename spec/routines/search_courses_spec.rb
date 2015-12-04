require 'rails_helper'

RSpec.describe SearchCourses, type: :routine do

  let!(:course_1) { FactoryGirl.create(:course_profile_profile).course }
  let!(:course_2) { FactoryGirl.create(:course_profile_profile).course }
  let!(:course_3) { FactoryGirl.create(:course_profile_profile).course }

  it 'returns all courses if no query is given' do
    courses = described_class[query: nil]
    expect(courses).to contain_exactly(course_1, course_2, course_3)
  end
end
