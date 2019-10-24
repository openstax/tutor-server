class Api::V1::Research::Sparfa::TaskPlansRequestRepresenter <
      Api::V1::Research::Sparfa::StudentsRequestRepresenter
  collection :task_plan_ids,
             type: String,
             readable: false,
             writeable: true
end
