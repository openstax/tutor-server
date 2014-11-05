class Section < ActiveRecord::Base
  belongs_to :klass
  has_many :students, dependent: :nullify

  has_many :educators, through: :klass
  has_one :course, through: :klass
  has_one :school, through: :course
  has_many :course_managers, through: :course
  has_many :school_managers, through: :school

  has_many :tasking_plans, as: :target, dependent: :destroy

  validates :klass, presence: true
  validates :name, presence: true, uniqueness: { scope: :klass_id }
end
