module Api::V1
  class TaskRepresenter < Roar::Decorator
    include Roar::Representer::JSON

    # property :id, 
    #          type: Integer,
    #          writeable: false,
    #          schema_info: {
    #            required: true
    #          }

    # property :taskable_id,
    #          type: Integer,
    #          writeable: false,
    #          schema_info: {
    #            required: true
    #          }             

    # property :taskable_type,
    #          type: String,
    #          writeable: false,
    #          schema_info: {
    #            required: true
    #          }             

    # property :user_id, 
    #          type: Integer,
    #          writeable: false,
    #          schema_info: {
    #            required: true,
    #            description: "The ID of the User to whom this Task is assigned"
    #          }

    property :task_plan_id, 
             type: Integer,
             writeable: false,
             readable: true,
             schema_info: {
               required: false,
               description: "The ID of the TaskPlan used to generate this Task"
             }

    property :opens_at,
             type: DateTime,
             writeable: true,
             readable: true,
             schema_info: {
               required: true,
               description: "When the task is available to be worked"
             }

    property :due_at,
             type: DateTime,
             writeable: true,
             readable: true,
             schema_info: {
               required: true,
               description: "When the task is due (nil means not due)"
             }

    property :is_shared,
             writeable: false,
             readable: true,
             schema_info: {
               required: true,
               description: "Whether or not the detailed task is shared ('turn in one assignment')"
             }

    # property :details,
    #          class: Api::V1::DetailedTaskRepresenter::SubModelFinder.new, # lambda { |hsh, *| Api::V1::DetailedTaskRepresenter.sub_model_for(hsh) },
    #          decorator: Api::V1::DetailedTaskRepresenter::SubRepresenterFinder.new, #lambda { |detailed_task, *| Api::V1::DetailedTaskRepresenter.sub_representer_for(detailed_task) },
    #          parse_strategy: :sync,
    #          schema_info: {
    #             required: true
    #          }

    class SubRepresenterFinder
      include Uber::Callable
 
      def call(*args)
        if args[0] == :all_sub_representers
          [Api::V1::ReadingRepresenter]
        else
          case args[0].class
          when Reading 
            Api::V1::ReadingRepresenter
          end
        end
      end
    end

  end
end
