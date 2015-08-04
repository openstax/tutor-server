module SchoolDistrict
  module Models
    class District < Tutor::SubSystems::BaseModel
      has_many :schools, subsystem: :school_district

      validates :name, presence: true, uniqueness: true

      before_destroy :check_no_schools

      protected

      def check_no_schools
        errors.add(:schools, 'must be empty') unless schools.empty?
        errors.any?
      end
    end
  end
end
