require 'rails_helper'

RSpec.describe CourseMembership::Models::Student, type: :model do
  let(:course)     { FactoryBot.create :course_profile_course }
  let(:period)     { FactoryBot.create :course_membership_period, course: course }
  let(:user)       { FactoryBot.create :user_profile }
  subject(:student) do
    AddUserAsPeriodStudent[user: user, period: period, student_identifier: 'N0B0DY'].student
  end

  it { is_expected.to belong_to(:course) }
  it { is_expected.to belong_to(:period) }
  it { is_expected.to belong_to(:role) }

  it { is_expected.to validate_uniqueness_of(:role) }

  [:username, :first_name, :last_name, :full_name].each do |method|
    it { is_expected.to delegate_method(method).to(:role) }
  end

  context '#is_refund_allowed' do
    it 'does not allow refunds if have not paid' do
      expect(student.is_refund_allowed).to eq false
    end

    it 'does not allow refunds if once paid but no longer' do
      student.update_attributes!(is_paid: true)
      student.update_attributes!(is_paid: false)
      expect(student.is_refund_allowed).to eq false
    end

    context 'have paid' do
      before(:each) { student.update_attributes!(is_paid: true) }

      it 'allows refunds after paying before 14 days elapse' do
        Timecop.freeze(Time.current + 13.8.days) do
          expect(student.is_refund_allowed).to eq true
        end
      end

      it 'does not allows refunds after paying after 14 days elapse' do
        Timecop.freeze(Time.current + 14.01.days) do
          expect(student.is_refund_allowed).to eq false
        end
      end
    end
  end
end
