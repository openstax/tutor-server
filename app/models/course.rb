class Course < ActiveRecord::Base
  belongs_to :school

  has_many :course_managers, dependent: :destroy
  has_many :klasses, dependent: :destroy

  has_many :students, through: :klasses
  has_many :educators, through: :klasses
  has_many :school_managers, through: :school

  has_many :tasking_plans, as: :target, dependent: :destroy

  validates :name, presence: true,
                   uniqueness: { scope: :school_id }
  validates :short_name, presence: true,
                         uniqueness: { scope: :school_id }
  validates :description, presence: true
end
