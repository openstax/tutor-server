class Course < ActiveRecord::Base
  belongs_to :school
  has_many :klasses, dependent: :destroy
  has_many :course_managers, dependent: :destroy
end
