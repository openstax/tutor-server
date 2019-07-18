class Api::V1::Demo::Assign::Representer < Roar::Decorator
  include Roar::JSON

  property :course_id,
           type: String,
           readable: true,
           writeable: true,
           schema_info: { required: true }

  collection :task_plans,
             extend: Api::V1::Demo::Assign::TaskPlan::Representer,
             readable: true,
             writeable: true,
             schema_info: { required: true }
end
