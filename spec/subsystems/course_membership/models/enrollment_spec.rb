require 'rails_helper'

module CourseMembership
  module Models
    RSpec.describe Enrollment, type: :model do
      let!(:period) { ::CreatePeriod[course: Entity::Course.create!].to_model }

      subject(:enrollment) {
        AddStudent[period: period, role: Entity::Role.create!].enrollments.first
      }

      it { is_expected.to belong_to(:period) }
      it { is_expected.to belong_to(:student) }

      it { is_expected.to validate_presence_of(:period) }
      it { is_expected.to validate_presence_of(:student) }
    end
  end
end
