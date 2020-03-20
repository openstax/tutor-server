class Api::V1::TaskPlan::Scores::StudentRepresenter < Roar::Decorator
  include Roar::JSON
  include Representable::Coercion

  property :name,
           type: String,
           readable: true,
           writeable: false

  property :student_identifier,
           type: String,
           readable: true,
           writeable: false

  property :is_dropped,
           readable: true,
           writeable: false

  property :available_points,
           type: Float,
           readable: true,
           writeable: false

  property :total_points,
           type: Float,
           readable: true,
           writeable: false

  property :total_fraction,
           type: Float,
           readable: true,
           writeable: false

  property :late_work_point_penalty,
           type: Float,
           readable: true,
           writeable: false

  property :late_work_fraction_penalty,
           type: Float,
           readable: true,
           writeable: false

         collection :questions,
             extend: Api::V1::TaskPlan::Scores::StudentQuestionRepresenter,
             readable: true,
             writeable: false
end
