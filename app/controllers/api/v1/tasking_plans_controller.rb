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

    tasks = case tasking_plan.target_type
    when 'CourseMembership::Models::Period'
      tasking_plan.task_plan.tasks.joins(taskings: { role: :student }).where(
        taskings: {
          role: { student: { course_membership_period_id: tasking_plan.target_id } }
        }
      )
    when 'CourseProfile::Models::Course'
      tasking_plan.task_plan.owner == tasking_plan.target ? tasking_plan.task_plan.tasks : []
    else
      raise NotImplementedError
    end

    Tasks::Models::TaskedExercise.joins(:task_step).where(
      task_step: { tasks_task_id: tasks.map(&:id) }
    ).update_all '"published_points" = "grader_points", "published_comments" = "grader_comments"'

    tasks.update_all grades_last_published_at: Time.current

    respond_with(
      tasking_plan,
      represent_with: Api::V1::TaskPlan::TaskingPlanRepresenter,
      responder: ResponderWithPutPatchDeleteContent
    )
  end
end