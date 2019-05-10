module SchoolDistrict
  module Models
    class District < ApplicationRecord
      has_many :schools

      validates :name, presence: true, uniqueness: true

      before_destroy :no_schools

      protected

      def no_schools
        return if schools.empty?

        errors.add :base, 'cannot be deleted because there are schools in it'
        throw :abort
      end
    end
  end
end
