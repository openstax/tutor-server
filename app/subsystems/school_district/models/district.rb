module SchoolDistrict
  module Models
    class District < ApplicationRecord
      has_many :schools

      validates :name, presence: true, uniqueness: true

      before_destroy :check_no_schools

      protected

      def check_no_schools
        schools.empty?
      end
    end
  end
end
