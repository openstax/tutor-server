class TimeZone < ActiveRecord::Base
  has_one :profile, class_name: 'CourseProfile::Models::Profile',
                    foreign_key: 'course_profile_profile_id'
  has_many :tasking_plans, class_name: 'Tasks::Models::TaskingPlan',
                           foreign_key: 'tasks_tasking_plans_id'
  has_many :tasks, class_name: 'Tasks::Models::Task', foreign_key: 'tasks_task_id'

  validates :name, presence: true, inclusion: { in: ActiveSupport::TimeZone.all.map(&:name) }

  def to_tz
    ActiveSupport::TimeZone[name]
  end
end
