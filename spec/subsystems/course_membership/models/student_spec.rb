require 'rails_helper'

RSpec.describe CourseMembership::Models::Student, type: :model do
  it { is_expected.to belong_to(:course) }
  it { is_expected.to belong_to(:role) }

  it { is_expected.to validate_presence_of(:course) }
  it { is_expected.to validate_presence_of(:role) }

  [:username, :first_name, :last_name, :full_name].each do |method|
    it { is_expected.to delegate_method(method).to(:role) }
  end

  context 'deidentifier' do
    let!(:user) { FactoryGirl.create(:user_profile).entity_user }
    let!(:period) { FactoryGirl.create(:period) }
    let!(:student) {
      AddUserAsPeriodStudent.call(period: period, user: user).outputs.student
    }

    it 'is generated before save and is 8 characters long' do
      expect(student.deidentifier.length).to eq 8
    end

    it 'stays the same after multiple saves' do
      old_deidentifier = student.deidentifier
      student.save
      expect(student.deidentifier).to eq old_deidentifier
    end

    it 'must be unique' do
      user2 = FactoryGirl.create(:user_profile).entity_user
      student_2 = AddUserAsPeriodStudent.call(period: period, user: user2).outputs.student
      student_2.deidentifier = student.deidentifier
      expect(student_2).not_to be_valid
      expect(student_2.errors.messages).to eq({
        deidentifier: ['has already been taken']
      })
    end
  end
end
