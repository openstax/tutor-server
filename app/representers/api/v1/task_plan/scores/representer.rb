class Api::V1::TaskPlan::Scores::Representer < ::Roar::Decorator
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

  property :description,
           type: String,
           readable: true,
           writeable: true

  collection :periods,
             extend: Api::V1::TaskPlan::Scores::PeriodRepresenter,
             readable: true,
             writable: false,
             getter: ->(*) { CalculateTaskPlanScores[task_plan: self] }
end
