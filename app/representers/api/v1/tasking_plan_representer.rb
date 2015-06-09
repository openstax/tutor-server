module Api::V1
  class TaskingPlanRepresenter < Roar::Decorator

    include Roar::JSON
    include Representable::Coercion

    TARGET_TYPE_TO_API_MAP = { 'CourseMembership::Models::Period' => 'period' }
    TARGET_TYPE_TO_CLASS_MAP = { 'period' => 'CourseMembership::Models::Period' }

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
             setter: lambda {|val, args| self.opens_at = Chronic.parse(val)}

    property :due_at,
             type: String,
             readable: true,
             writeable: true,
             setter: lambda {|val, args|
                orig_time = Chronic.parse(val)
                new_time  = orig_time.midnight + 7.hours
                self.due_at = new_time
             }

  end
end
