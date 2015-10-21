require 'rails_helper'

RSpec.describe CourseMembership::Models::Student, type: :model do
  let!(:period)     { CreatePeriod[course: Entity::Course.create!].to_model }
  let!(:user)       { FactoryGirl.create(:user) }
  subject(:student) { AddUserAsPeriodStudent[user: user, period: period].student }

  it { is_expected.to belong_to(:course) }
  it { is_expected.to belong_to(:role) }

  it { is_expected.to validate_presence_of(:course) }
  it { is_expected.to validate_presence_of(:role) }

  it { is_expected.to validate_uniqueness_of(:role) }

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

    it 'must be unique' do
      user2 = FactoryGirl.create(:user)
      student_2 = AddUserAsPeriodStudent.call(period: period, user: user2).outputs.student
      student_2.deidentifier = student.deidentifier
      expect(student_2).not_to be_valid
      expect(student_2.errors.messages).to eq({
        deidentifier: ['has already been taken']
      })
    end
  end
end
