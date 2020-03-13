class Api::V1::TaskPlan::Scores::Student::QuestionRepresenter < Roar::Decorator
  include Roar::JSON

  property :index,
           type: Integer,
           readable: true,
           writeable: false

  property :points,
           type: Float,
           readable: true,
           writeable: false

  property :is_trouble,
           readable: true,
           writeable: false
end
