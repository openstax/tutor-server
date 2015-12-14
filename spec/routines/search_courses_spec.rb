require 'rails_helper'

RSpec.describe SearchCourses, type: :routine do

  let!(:tutor_school) { FactoryGirl.create(:school, name: 'TTS') }
  let!(:cc_school)    { FactoryGirl.create(:school, name: 'CCS') }

  let!(:course_1) { FactoryGirl.create(
    :course_profile_profile, name: 'Physics', school: tutor_school
  ).course }
  let!(:course_2) { FactoryGirl.create(
    :course_profile_profile, name: 'Biology', school: tutor_school
  ).course }
  let!(:course_3) { FactoryGirl.create(
    :course_profile_profile, name: 'Concept Coach', school: cc_school
  ).course }

  let!(:teacher_user) { FactoryGirl.create(:user, first_name: 'Charles') }

  before do
    AddUserAsCourseTeacher.call(course: course_1, user: teacher_user)
    AddUserAsCourseTeacher.call(course: course_3, user: teacher_user)
  end

  it 'returns all courses in alphabetical order if the query is nil' do
    courses = described_class.call(query: nil).to_a
    expect(courses).to eq [course_2, course_3, course_1]
  end

  it 'returns all courses in alphabetical order if the query is blank' do
    courses = described_class.call(query: '').to_a
    expect(courses).to eq [course_2, course_3, course_1]
  end

  it 'returns courses whose name matches the given query, in alphabetical order' do
    courses = described_class.call(query: 'i').to_a
    expect(courses).to eq [course_2, course_1]

    courses = described_class.call(query: 'o').to_a
    expect(courses).to eq [course_2, course_3]

    courses = described_class.call(query: 'bIo').to_a
    expect(courses).to eq [course_2]

    courses = described_class.call(query: 'physics').to_a
    expect(courses).to eq [course_1]
  end

  it 'returns courses whose school\'s name matches the given query, in alphabetical order' do
    courses = described_class.call(query: 'ts').to_a
    expect(courses).to eq [course_2, course_1]

    courses = described_class.call(query: 'ccs').to_a
    expect(courses).to eq [course_3]
  end

  it 'returns courses whose teacher\'s name matches the given query, in alphabetical order' do
    courses = described_class.call(query: 'cHaRlEs').to_a
    expect(courses).to eq [course_3, course_1]

    courses = described_class.call(query: 'rLe').to_a
    expect(courses).to eq [course_3, course_1]
  end
end
