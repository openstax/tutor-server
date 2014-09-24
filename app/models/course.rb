class Course < ActiveRecord::Base
  belongs_to :school
  has_many :klasses, dependent: :destroy
  has_many :course_managers, dependent: :destroy

  validates :name, presence: true,
                   uniqueness: { scope: :school_id }
  validates :short_name, presence: true,
                         uniqueness: { scope: :school_id }
  validates :description, presence: true
end
