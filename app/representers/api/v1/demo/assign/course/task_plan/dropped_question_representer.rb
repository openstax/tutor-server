class Api::V1::Demo::Assign::Course::TaskPlan::DroppedQuestionRepresenter < Api::V1::Demo::BaseRepresenter
  property :question_index,
           type: Integer,
           readable: true,
           writeable: true,
           getter: ->(*) do
             question_index = nil
             task_plan.tasks.each do |task|
               question_index = task.tasked_exercises.index { |te| te.question_id == question_id }
               break unless question_index.nil?
             end
             question_index
           end

  property :drop_method,
           type: String,
           readable: true,
           writeable: true,
           schema_info: { required: true }
end
