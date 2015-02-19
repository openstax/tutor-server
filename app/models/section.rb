class Section < ActiveRecord::Base
  belongs_to :course
  has_many :students, dependent: :nullify

  has_many :tasking_plans, as: :target, dependent: :destroy

  validates :course, presence: true
  validates :name, presence: true, uniqueness: { scope: :course_id }
end
