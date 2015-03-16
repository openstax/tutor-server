class Api::V1::TaskPlansController < Api::V1::ApiController

  resource_description do
    api_versions "v1"
    short_description 'Represents a plan for a Task'
    description <<-EOS
      TaskPlans store information that assistants can use to generate Tasks.
    EOS
  end

  ###############################################################
  # show
  ###############################################################

  api :GET, '/courses/:course_id/plans/:id', 'Gets the specified TaskPlan'
  description <<-EOS
    #{json_schema(Api::V1::TaskPlanRepresenter, include: :readable)}
  EOS
  def show
    standard_read(TaskPlan.find(params[:id]))
  end

  ###############################################################
  # post
  ###############################################################

  api :POST, '/courses/:course_id/plans', 'Creates a TaskPlan'
  description <<-EOS
    #{json_schema(Api::V1::TaskPlanRepresenter, include: :writeable)}
  EOS
  def create
    # TODO: Routine to get the course by ID
    # TODO: Figure out the course assistant from the type
    course = Entity::Course.find(params[:course_id])
    assistant = Assistant.last
    standard_create(TaskPlan.new) do |task_plan|
      task_plan.owner = course
      task_plan.assistant = assistant
    end
  end

  ###############################################################
  # update
  ###############################################################

  api :PUT, '/courses/:course_id/plans/:id', 'Updates the specified TaskPlan'
  description <<-EOS
    #{json_schema(Api::V1::TaskPlanRepresenter, include: :writeable)}
  EOS
  def update
    standard_update(TaskPlan.find(params[:id]))
  end

  ###############################################################
  # publish
  ###############################################################

  api :POST, '/courses/:course_id/plans/:id/publish',
               'Publishes the specified TaskPlan'
  description <<-EOS
    #{json_schema(Api::V1::TaskPlanRepresenter, include: :writeable)}
  EOS
  def publish
    task_plan = TaskPlan.find(params[:id])
    OSU::AccessPolicy.require_action_allowed!(:publish,
                                              current_api_user,
                                              task_plan)
    DistributeTasks.call(task_plan)
    respond_with task_plan
  end

  ###############################################################
  # destroy
  ###############################################################

  api :DELETE, '/courses/:course_id/plans/:id',
               'Deletes the specified TaskPlan'
  description <<-EOS
    #{json_schema(Api::V1::TaskPlanRepresenter, include: :writeable)}
  EOS
  def destroy
    standard_destroy(TaskPlan.find(params[:id]))
  end

  
end
