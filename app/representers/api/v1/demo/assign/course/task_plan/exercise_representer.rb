class Api::V1::Demo::Assign::Course::TaskPlan::ExerciseRepresenter < Api::V1::Demo::BaseRepresenter
  property :number,
           type: Integer,
           readable: false,
           writeable: true,
           schema_info: { required: true }

  property :points,
           type: Array,
           readable: false,
           writeable: true,
           schema_info: { required: true }
end
