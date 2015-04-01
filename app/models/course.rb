class Course < ActiveRecord::Base
  has_many :sections, dependent: :destroy
  has_many :educators, dependent: :destroy
  has_many :students, dependent: :destroy

  has_many :tasking_plans, as: :target, dependent: :destroy
  has_many :task_plans, as: :owner, dependent: :destroy

  has_many :course_assistants, dependent: :destroy

  validates :school, presence: true
  validates :name, presence: true, uniqueness: { scope: :school }
  validates :short_name, presence: true, uniqueness: { scope: :school }
  validates :time_zone, presence: true,
                        inclusion: {
                          in: ActiveSupport::TimeZone.all.map(&:to_s)
                        }
end
