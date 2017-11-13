require 'rails_helper'

module CourseMembership
  module Models
    describe Enrollment, type: :model do
      let(:course) { FactoryBot.create :course_profile_course }
      let(:period) { FactoryBot.create :course_membership_period, course: course }
      let(:role)   { FactoryBot.create :entity_role }

      subject(:enrollment) { AddStudent[period: period, role: role].enrollments.first }

      it { is_expected.to belong_to(:period) }
      it { is_expected.to belong_to(:student) }

      it { is_expected.to validate_presence_of(:period) }
      it { is_expected.to validate_presence_of(:student) }

      it 'requires student and period to belong to the same course' do
        expect(enrollment).to be_valid

        enrollment.period = FactoryBot.create :course_membership_period
        expect(enrollment).not_to be_valid
        expect(enrollment.errors[:base]).to include(
          'must have a student and a period that belong to the same course'
        )
      end
    end
  end
end
