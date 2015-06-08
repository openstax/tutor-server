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

    property :published_at,
             type: String,
             readable: true,
             writeable: true,
             setter: lambda {|val, args| self.published_at = Chronic.parse(val)}

    property :settings,
             type: Object,
             readable: true,
             writeable: true

    collection :tasking_plans,
               as: :periods,
               class: ::Tasks::Models::TaskingPlan,
               decorator: TaskingPlanPeriodRepresenter,
               readable: true,
               writeable: true

  end
end
