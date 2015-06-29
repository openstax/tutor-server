module Api::V1
  class TaskingPlanRepresenter < Roar::Decorator

    include Roar::JSON
    include Representable::Coercion

    TARGET_TYPE_TO_API_MAP = { 'CourseMembership::Models::Period' => 'period',
                               'Entity::Course' => 'course' }
    TARGET_TYPE_TO_CLASS_MAP = { 'period' => 'CourseMembership::Models::Period',
                                 'course' => 'Entity::Course' }

    property :target_id,
             type: String,
             readable: true,
             writeable: true

    property :target_type,
             type: String,
             readable: true,
             writeable: true,
             getter: ->(*) { TARGET_TYPE_TO_API_MAP[target_type] },
             setter: ->(val, *) { self.target_type = TARGET_TYPE_TO_CLASS_MAP[val] }

    property :opens_at,
             type: String,
             readable: true,
             writeable: true,
             getter: ->(*) { DateTimeUtilities.to_api_s(opens_at) },
             setter: ->(val, *) {
               orig_time = DateTimeUtilities.from_api_s(val)
               new_time  = orig_time.in_time_zone.midnight + 1.minute
               self.opens_at = new_time
             }

    property :due_at,
             type: String,
             readable: true,
             writeable: true,
             getter: ->(*) { DateTimeUtilities.to_api_s(due_at) },
             setter: ->(val, *) {
               orig_time = DateTimeUtilities.from_api_s(val)
               new_time  = orig_time.in_time_zone.midnight + 7.hours
               self.due_at = new_time
             }

  end
end
