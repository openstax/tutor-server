class Api::V1::TaskingPlansController < Api::V1::ApiController
  resource_description do
    api_versions 'v1'
    short_description 'Represents a TaskPlan assigned to a Course Period'
    description <<-EOS
      TaskingPlans store information about open, due and close dates and grade publication.
    EOS
  end

  ###############################################################
  # grade
  ###############################################################

  api :PUT, '/tasking_plans/:id/grade', "Publishes the specified TaskingPlan's grades"
  description <<-EOS
    #{json_schema(Api::V1::TaskPlan::TaskingPlanRepresenter, include: :readable)}
  EOS
  def grade
    tasking_plan = Tasks::Models::TaskingPlan.find params[:id]

    OSU::AccessPolicy.require_action_allowed!(:grade, current_api_user, tasking_plan)

    tasking_plan.update_attribute :grades_published_at, Time.current

    respond_with(
      tasking_plan,
      represent_with: Api::V1::TaskPlan::TaskingPlanRepresenter,
      responder: ResponderWithPutPatchDeleteContent
    )
  end
end
