module Api::V1
  class TaskPlanRepresenter < Roar::Decorator

    include Roar::JSON
    include Representable::Coercion

    property :id,
             type: String,
             readable: true,
             writeable: false

    property :type,
             type: String,
             readable: true,
             writeable: true

    property :title,
             type: String,
             readable: true,
             writeable: true

    property :opens_at,
             type: String,
             readable: true,
             writeable: true,
             setter: lambda {|val, args| self.opens_at = Chronic.parse(val)}

    property :published_at,
             type: String,
             readable: true,
             writeable: true,
             setter: lambda {|val, args| self.published_at = Chronic.parse(val)}

    property :due_at,
             type: String,
             readable: true,
             writeable: true,
             setter: lambda {|val, args|
                orig_time = Chronic.parse(val)
                new_time  = orig_time.midnight + 7.hours
                self.due_at = new_time
             }

    property :settings,
             type: Object,
             readable: true,
             writeable: true

  end
end
