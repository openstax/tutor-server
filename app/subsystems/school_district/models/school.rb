module SchoolDistrict
  module Models
    class School < Tutor::SubSystems::BaseModel
      has_many :profiles, subsystem: :course_profile
      belongs_to :district

      validates :name, presence: true,
                       uniqueness: { scope: :school_district_district_id }

      before_destroy :check_no_courses

      delegate :name,
               to: :district,
               prefix: true,
               allow_nil: true

      protected

      def check_no_courses
        errors.add(:base, 'Cannot delete a school that has courses.') unless profiles.empty?
        errors.none?
      end
    end
  end
end
