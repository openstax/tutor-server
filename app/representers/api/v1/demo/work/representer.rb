class Api::V1::Demo::Work::Representer < Roar::Decorator
  include Roar::JSON

  property :course_id,
           type: String,
           readable: true,
           writeable: true,
           schema_info: { required: true }

  property :task_plan_id,
           type: String,
           readable: true,
           writeable: true

  collection :work,
             extend: Api::V1::Demo::Work::StatusRepresenter,
             readable: true,
             writeable: true,
             schema_info: { required: true }
end
