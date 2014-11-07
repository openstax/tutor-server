class Klass < ActiveRecord::Base
  belongs_to :course
  has_many :sections, dependent: :destroy
  has_many :educators, dependent: :destroy
  has_many :students, dependent: :destroy

  has_many :tasking_plans, as: :target, dependent: :destroy
  has_many :task_plans, as: :owner, dependent: :destroy

  has_many :topics, dependent: :destroy
  has_many :exercise_definitions, dependent: :destroy

  validates :course, presence: true
  validates :time_zone, allow_nil: true,
                        inclusion: {
                          in: ActiveSupport::TimeZone.all.map(&:to_s)
                        }
end
