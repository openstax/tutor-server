class TimeZone < ActiveRecord::Base
  has_one :course, class_name: 'CourseProfile::Models::Course'
  has_many :tasking_plans, class_name: 'Tasks::Models::TaskingPlan'
  has_many :tasks, class_name: 'Tasks::Models::Task'

  validates :name, presence: true, inclusion: { in: ActiveSupport::TimeZone.all.map(&:name) }

  def to_tz
    ActiveSupport::TimeZone[name]
  end
end
