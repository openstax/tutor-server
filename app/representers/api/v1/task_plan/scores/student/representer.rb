class Api::V1::TaskPlan::Scores::Student::Representer < Roar::Decorator
  include Roar::JSON

  property :name,
           type: String,
           readable: true,
           writeable: false

  property :is_dropped,
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

  collection :questions,
             readable: true,
             writeable: false,
             extend: Api::V1::TaskPlan::Scores::Student::QuestionRepresenter
end
