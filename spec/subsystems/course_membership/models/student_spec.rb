require 'rails_helper'

RSpec.describe CourseMembership::Models::Student, type: :model do
  let(:course)     { FactoryGirl.create :course_profile_course }
  let(:period)     { FactoryGirl.create :course_membership_period, course: course }
  let(:user)       { FactoryGirl.create :user }
  subject(:student) do
    AddUserAsPeriodStudent[user: user, period: period, student_identifier: 'N0B0DY'].student
  end

  it { is_expected.to belong_to(:course) }
  it { is_expected.to belong_to(:role) }

  it { is_expected.to validate_presence_of(:course) }
  it { is_expected.to validate_presence_of(:role) }

  it { is_expected.to validate_uniqueness_of(:role) }
  it { is_expected.to validate_uniqueness_of(:deidentifier) }

  [:username, :first_name, :last_name, :full_name].each do |method|
    it { is_expected.to delegate_method(method).to(:role) }
  end

  context 'deidentifier' do
    it 'is generated before save and is 8 characters long' do
      expect(student.deidentifier.length).to eq 8
    end

    it 'stays the same after multiple saves' do
      old_deidentifier = student.deidentifier
      student.save
      expect(student.deidentifier).to eq old_deidentifier
    end
  end
end
