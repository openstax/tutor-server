require 'rails_helper'

module CourseMembership
  module Models
    RSpec.describe Enrollment, type: :model do
      subject(:enrollment) {
        period = ::CreatePeriod[course: Entity::Course.create!].to_model
        AddStudent[period: period, role: Entity::Role.create!].enrollments.first
      }

      it { is_expected.to belong_to(:period) }
      it { is_expected.to belong_to(:student) }

      it { is_expected.to validate_presence_of(:period) }
      it { is_expected.to validate_presence_of(:student) }

      it {
        is_expected.to validate_uniqueness_of(:student).scoped_to(:course_membership_period_id)
      }
    end
  end
end
