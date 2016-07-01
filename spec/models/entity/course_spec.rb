require 'rails_helper'

RSpec.describe Entity::Course, type: :model do
  it { is_expected.to have_one(:profile).dependent(:destroy).autosave(true) }

  it { is_expected.to have_many(:periods).dependent(:destroy) }
  it { is_expected.to have_many(:teachers).dependent(:destroy) }
  it { is_expected.to have_many(:students).dependent(:destroy) }

  it { is_expected.to have_many(:course_ecosystems).dependent(:destroy) }
  it { is_expected.to have_many(:ecosystems) }

  it { is_expected.to have_many(:course_assistants).dependent(:destroy) }

  it { is_expected.to have_many(:taskings) }

  it { is_expected.to delegate_method(:name).to(:profile) }
  it { is_expected.to delegate_method(:appearance_code).to(:profile) }
  it { is_expected.to delegate_method(:is_concept_coach).to(:profile) }
  it { is_expected.to delegate_method(:offering).to(:profile) }
  it { is_expected.to delegate_method(:teach_token).to(:profile) }

  it 'knows if it is deletable' do
    course = FactoryGirl.create :entity_course
    expect(course).to be_deletable

    user = FactoryGirl.create :user
    period = FactoryGirl.create(:course_membership_period, course: course)

    expect(course.reload).not_to be_deletable

    student = AddUserAsPeriodStudent[user: user, period: period].student

    expect(course.reload).not_to be_deletable

    student.destroy

    expect(course.reload).not_to be_deletable

    period.destroy

    expect(course.reload).to be_deletable

    teacher = AddUserAsCourseTeacher[user: user, course: course].teacher
    expect(course.reload).not_to be_deletable
    teacher.destroy
    expect(course.reload).to be_deletable
  end
end
