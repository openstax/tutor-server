class Api::V1::TaskPlan::Scores::PeriodRepresenter < Roar::Decorator
  include Roar::JSON

  property :id,
           type: String,
           readable: true,
           writeable: false

  property :name,
           type: String,
           readable: true,
           writeable: false

  collection :data_headings,
             readable: true,
             writeable: false,
             extend: Api::V1::TaskPlan::Scores::QuestionHeadingRepresenter

  property :available_points,
           readable: true,
           writeable: false,
           extend: Api::V1::TaskPlan::Scores::Student::Representer

  property :questions_dropped,
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
             extend: Api::V1::TaskPlan::Scores::Student::Representer

  property :average_score,
           readable: true,
           writeable: false,
           extend: Api::V1::TaskPlan::Scores::Student::Representer
end
