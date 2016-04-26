module Api::V1
  class TaskingPlanRepresenter < Roar::Decorator

    include Roar::JSON
    include Representable::Coercion

    TARGET_TYPE_TO_API_MAP = { 'CourseMembership::Models::Period' => 'period',
                               'Entity::Course' => 'course' }
    TARGET_TYPE_TO_CLASS_MAP = { 'period' => 'CourseMembership::Models::Period',
                                 'course' => 'Entity::Course' }

    property :tasks_task_plan_id,
             type: String,
             readable: true,
             writeable: true,
             schema_info: {
               required: true
             }

    property :target_id,
             type: String,
             readable: true,
             writeable: true,
             schema_info: {
               required: true
             }

    property :target_type,
             type: String,
             readable: true,
             writeable: true,
             getter: ->(*) { TARGET_TYPE_TO_API_MAP[target_type] },
             setter: ->(val, *) { self.target_type = TARGET_TYPE_TO_CLASS_MAP[val] },
             schema_info: {
               required: true
             }

    property :opens_at,
             type: String,
             readable: true,
             writeable: true,
             getter: ->(*) { DateTimeUtilities.to_api_s(opens_at) },
             setter: ->(val, *) { self.opens_at = TaskingPlanRepresenter.set_time_zone(self, val) },
             schema_info: {
               required: true
             }

    property :due_at,
             type: String,
             readable: true,
             writeable: true,
             getter: ->(*) { DateTimeUtilities.to_api_s(due_at) },
             setter: ->(val, *) { self.due_at = TaskingPlanRepresenter.set_time_zone(self, val) },
             schema_info: {
               required: true
             }

    def self.set_time_zone(tasking_plan, time_str)
      # if owner is not a course, we can't get the timezone
      tz_name = tasking_plan.task_plan.owner.try(:timezone)
      default_time_zone = ActiveSupport::TimeZone['Central Time (US & Canada)']
      course_time_zone = ActiveSupport::TimeZone[tz_name] rescue default_time_zone
      # get rid of the timezone in time_str
      time_str = $1 if /^(.*) ?[-+]\d\d(?::?\d\d)/.match(time_str)
      course_time_zone.parse(time_str)
    end

  end

end
