module SchoolDistrict
  module Models
    class School < ApplicationRecord
      has_many :courses, subsystem: :course_profile

      belongs_to :district, optional: true

      validates :name, presence: true, uniqueness: { scope: :school_district_district_id }

      before_destroy :no_courses

      delegate :name, to: :district, prefix: true, allow_nil: true

      protected

      def no_courses
        return if courses.empty?

        errors.add :base, 'cannot be deleted because there are courses in it'
        throw :abort
      end
    end
  end
end
