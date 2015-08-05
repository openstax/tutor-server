module SchoolDistrict
  module Models
    class District < Tutor::SubSystems::BaseModel
      has_many :schools

      validates :name, presence: true, uniqueness: true

      before_destroy :check_no_schools

      protected

      def check_no_schools
        errors.add(:base, 'Cannot delete a district that has schools.') unless schools.empty?
        errors.none?
      end
    end
  end
end
