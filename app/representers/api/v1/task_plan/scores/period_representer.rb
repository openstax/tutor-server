class Api::V1::TaskPlan::Scores::PeriodRepresenter < Roar::Decorator
  include Roar::JSON
  include Representable::Coercion

  property :id,
           type: String,
           readable: true,
           writeable: false

  property :name,
           type: String,
           readable: true,
           writeable: false

  collection :question_headings,
             readable: true,
             writeable: false,
             extend: Api::V1::TaskPlan::Scores::QuestionHeadingRepresenter

  property :late_work_fraction_penalty,
           type: Float,
           readable: true,
           writeable: false

  property :available_points,
           readable: true,
           writeable: false,
           extend: Api::V1::TaskPlan::Scores::StudentRepresenter

  property :num_questions_dropped,
           type: Integer,
           readable: true,
           writeable: false

  property :points_dropped,
           type: Float,
           readable: true,
           writeable: false

  collection :students,
             readable: true,
             writeable: false,
             extend: Api::V1::TaskPlan::Scores::StudentRepresenter

  property :average_score,
           readable: true,
           writeable: false,
           extend: Api::V1::TaskPlan::Scores::StudentRepresenter
end
