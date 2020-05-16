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

  property :content_ecosystem_id,
           as: :ecosystem_id,
           type: String,
           readable: true,
           writeable: true

  property :grading_template,
           extend: Api::V1::GradingTemplateRepresenter,
           readable: true,
           writeable: false

  collection :dropped_questions,
             class: ::Tasks::Models::DroppedQuestion,
             extend: Api::V1::TaskPlan::DroppedQuestionRepresenter,
             readable: true,
             writeable: false

  collection :tasking_plans,
             extend: Api::V1::TaskPlan::Scores::TaskingPlanRepresenter,
             readable: true,
             writeable: false,
             getter: ->(*) { CalculateTaskPlanScores[task_plan: self] }
end
