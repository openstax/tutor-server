module Api::V1
  class TaskingPlanPeriodRepresenter < Roar::Decorator

    include Roar::JSON
    include Representable::Coercion

    property :id,
             type: String,
             readable: true,
             writeable: true,
             getter: ->(*) { target.try(:id) },
             setter: ->(val, *) {
              self.target = CourseMembership::Models::Period.find(val)
            }

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
