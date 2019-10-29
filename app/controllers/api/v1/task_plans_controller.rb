class Api::V1::TaskPlansController < Api::V1::ApiController
  resource_description do
    api_versions "v1"
    short_description 'Represents a plan for a Task'
    description <<-EOS
      TaskPlans store information that assistants can use to generate Tasks.
    EOS
  end

  ###############################################################
  # index
  ###############################################################

  api :GET, '/courses/:course_id/plans', 'Retrieve course TaskPlans according to params'
  description <<-EOS
   Valid params:

   clone_status == unused_source -> if the current course was cloned, returns only task plans
                                    in the original course that have not been cloned into this one
   clone_status == used_source   -> if the current course was cloned, returns only task plans
                                    in the original course that have been cloned into this one
   clone_status == original      -> returns only task plans in the current course
                                    that are not clones of any other task plan
   clone_status == clone         -> returns only task plans in the current course
                                    that are clones of some other task plan

   ### Example JSON response
   #{json_schema(Api::V1::TaskPlanSearchRepresenter, include: :readable)}
  EOS
  def index
    course = CourseProfile::Models::Course.find(params[:course_id])
    OSU::AccessPolicy.require_action_allowed!(:read_task_plans, current_api_user, course)

    case params[:clone_status]
    when 'unused_source', 'used_source'
      source_course = course.cloned_from
      cloned_task_plan_ids = Tasks::Models::TaskPlan.where(owner: course).pluck(:cloned_from_id)
    else
      source_course = course
    end

    if source_course.nil?
      task_plans = Tasks::Models::TaskPlan.none
    else
      tps = Tasks::Models::TaskPlan.where(owner: source_course)
                                   .without_deleted
                                   .preload_tasking_plans

      task_plans = case params[:clone_status]
      when 'unused_source'
        tps.where.not(id: cloned_task_plan_ids)
      when 'used_source'
        tps.where(id: cloned_task_plan_ids)
      when 'original'
        tps.where(cloned_from_id: nil)
      when 'clone'
        tps.where.not(cloned_from_id: nil)
      else
        tps
      end
    end

    respond_with(Lev::Outputs.new(items: task_plans),
                 user_options: { exclude_job_info: true },
                 represent_with: Api::V1::TaskPlanSearchRepresenter)
  end

  ###############################################################
  # show
  ###############################################################

  api :GET, '/plans/:id', "Retrieve a TaskPlan"
  description <<-EOS
   ### Example JSON response
   #{json_schema(Api::V1::TaskPlanRepresenter, include: :readable)}
  EOS
  def show
    plan = Tasks::Models::TaskPlan.preload_tasking_plans.find(params[:id])
    standard_read(plan, Api::V1::TaskPlanRepresenter)
  end

  ###############################################################
  # post
  ###############################################################

  api :POST, '/courses/:course_id/plans', 'Creates a TaskPlan'
  description <<-EOS
### IReading settings:

<pre class="code">
#{Tasks::Assistants::IReadingAssistant.schema}
</pre>

### Homework settings:

<pre class="code">
#{Tasks::Assistants::HomeworkAssistant.schema}
</pre>

### External assignment settings:

<pre class="code">
#{Tasks::Assistants::ExternalAssignmentAssistant.schema}
</pre>

### Event assignment settings:

<pre class="code">
#{Tasks::Assistants::EventAssistant.schema}
</pre>

    #{json_schema(Api::V1::TaskPlanRepresenter, include: :writeable)}
  EOS
  def create
    # Modified standard_create code
    Tasks::Models::TaskPlan.transaction do
      course = CourseProfile::Models::Course.find(params[:course_id])
      task_plan = Tasks::Models::TaskPlan.new(owner: course)
      consume!(task_plan, represent_with: Api::V1::TaskPlanRepresenter)
      task_plan.assistant = Tasks::GetAssistant[course: course, task_plan: task_plan]

      raise(IllegalState, "No assistant for task plan of type #{task_plan.type}") \
        if task_plan.assistant.nil?

      OSU::AccessPolicy.require_action_allowed!(:create, current_api_user, task_plan)

      # If this is a cloned assignment, update its ecosystem during creation
      task_plan = UpdateTaskPlanEcosystem[
        task_plan: task_plan, ecosystem: course.ecosystem, save: false
      ] if task_plan.cloned_from_id.present?

      uuid = distribute_tasks task_plan

      render_api_errors(task_plan.errors) && return

      ShortCode::Create[task_plan.to_global_id.to_s]

      respond_with task_plan, represent_with: Api::V1::TaskPlanRepresenter,
                              status: uuid.nil? ? :ok : :accepted,
                              location: nil
    end
  end

  ###############################################################
  # update
  ###############################################################

  api :PUT, '/plans/:id', 'Updates the specified TaskPlan'
  description <<-EOS
    #{json_schema(Api::V1::TaskPlanRepresenter, include: :writeable)}
  EOS
  def update
    Tasks::Models::TaskPlan.transaction do
      # Modified standard_update code
      task_plan = Tasks::Models::TaskPlan.preload_tasking_plans.preload_tasks.lock.find(params[:id])
      OSU::AccessPolicy.require_action_allowed!(:update, current_api_user, task_plan)
      course = task_plan.owner

      if task_plan.out_to_students?
        # Store current open dates for all TaskingPlans that are already open
        opens_at_ntzs = Hash.new { |hash, key| hash[key] = {} }
        open_tasking_plans = task_plan.tasking_plans.select(&:past_open?)
        open_tasking_plans.each do |tp|
          opens_at_ntzs[tp.target_type][tp.target_id] = tp.opens_at_ntz
        end

        # Call Roar's consume! but force the TaskingPlans that were already open
        # to the old open date in order to prevent their open dates from changing
        consume!(task_plan, represent_with: Api::V1::TaskPlanRepresenter).tap do |result|
          task_plan.tasking_plans.each do |tp|
            tp.update_attribute(:opens_at_ntz, opens_at_ntzs[tp.target_type][tp.target_id]) \
              if opens_at_ntzs[tp.target_type].has_key?(tp.target_id)
          end
        end
      else
        # If no tasks are open, just call Roar's consume! like usual
        consume!(task_plan, represent_with: Api::V1::TaskPlanRepresenter)
      end

      OSU::AccessPolicy.require_action_allowed!(:update, current_api_user, task_plan)
      uuid = distribute_tasks task_plan

      render_api_errors(task_plan.errors) || respond_with(
        task_plan,
        represent_with: Api::V1::TaskPlanRepresenter,
        responder: ResponderWithPutPatchDeleteContent,
        status: uuid.nil? ? :ok : :accepted
      )
    end
  end

  ###############################################################
  # stats
  ###############################################################

  api :GET, '/plans/:id/stats', "Retrieve a TaskPlan along with its statistics"
  description <<-EOS
    ### Example JSON response
    <pre class='code'>
    {
        "id": 2543,
        "type": "reading",
        "stats": {
            "course": {
                "mean_grade_percent": 50,
                "total_count": 2,
                "complete_count": 0,
                "partially_complete_count": 2,
                "current_pages": [
                    {
                        "id": 1125,
                        "number": 1,
                        "title": "Force",
                        "student_count": 2,
                        "correct_count": 1,
                        "incorrect_count": 1
                    }
                ],
                "spaced_pages": [
                    {
                        "id": 0,
                        "number": 0,
                        "title": "",
                        "student_count": 0,
                        "correct_count": 0,
                        "incorrect_count": 0
                    }
                ]
            },
            "periods": []
        }
    }
    </pre>
    #{json_schema(Api::V1::TaskPlanWithStatsRepresenter, include: :readable)}
  EOS
  def stats
    plan = Tasks::Models::TaskPlan.preload_tasking_plans.find(params[:id])
    standard_read(plan, Api::V1::TaskPlanWithStatsRepresenter)
  end

  ###############################################################
  # review
  ###############################################################

  api :GET, '/plans/:id/review', "Retrieve a TaskPlan along with its detailed statistics"
  description <<-EOS
    ### Example JSON response
    <pre class='code'>
    {
        "id": 2543,
        "type": "reading",
        "stats": {
            "course": {
                "mean_grade_percent": 50,
                "total_count": 2,
                "complete_count": 0,
                "partially_complete_count": 2,
                "current_pages": [
                    {
                        "id": 1125,
                        "number": 1,
                        "title": "Force",
                        "student_count": 2,
                        "correct_count": 1,
                        "incorrect_count": 1,
                        "exercises": [
                            {
                                "content": {
                                    "uid": "1@1",
                                    "number": 1,
                                    "version": 1,
                                    "first_published_at": "2015-04-22T19:30:19.187Z",
                                    "last_published_at": "2015-04-22T19:30:19.187Z",
                                    "editors": [],
                                    "authors": [
                                        {
                                            "user_id": 1
                                        }
                                    ],
                                    "copyright_holders": [
                                        {
                                            "user_id": 2
                                        }
                                    ],
                                    "derived_from": [],
                                    "attachments": [],
                                    "tags": [
                                        "k12phys-ch04-s01-lo01",
                                        "k12phys-ch04-ex001",
                                        "os-practice-concepts",
                                        "inbook-yes",
                                        "dok1",
                                        "time-short",
                                        "display-free-response"
                                    ],
                                    "stimulus_html": "",
                                    "questions": [
                                        {
                                            "id": 464,
                                            "stimulus_html": "",
                                            "stem_html": "What is kinematics?",
                                            "answers": [
                                                {
                                                    "id": 1683,
                                                    "content_html": "Kinematics is the study of atomic structure",
                                                    "correctness": "0.0",
                                                    "feedback_html": "Are you sure that the study of atomic structures is a part of kinematics?",
                                                    "selected_count": 1
                                                },
                                                {
                                                    "id": 1682,
                                                    "content_html": "Kinematics is the study of dimensions",
                                                    "correctness": "0.0",
                                                    "feedback_html": "Is it correct to say that dimensional analysis is done in kinematics?",
                                                    "selected_count": 0
                                                },
                                                {
                                                    "id": 1681,
                                                    "content_html": "Kinematics is the study of cause of motion",
                                                    "correctness": "0.0",
                                                    "feedback_html": "Do you think cause of motion is studied under kinematics? What about the study of force and its effect on a body. Is that kinematics?",
                                                    "selected_count": 0
                                                },
                                                {
                                                    "id": 1680,
                                                    "content_html": "Kinematics is the study of motion",
                                                    "correctness": "1.0",
                                                    "feedback_html": "Correct! Motion of a body is studied under kinematics",
                                                    "selected_count": 1
                                                }
                                            ],
                                            "hints": [],
                                            "formats": [
                                                "multiple-choice",
                                                "free-response"
                                            ],
                                            "combo_choices": []
                                        }
                                    ]
                                },
                                "answered_count": 2
                            }
                        ]
                    }
                ],
                "spaced_pages": [
                    {
                        "id": 0,
                        "number": 0,
                        "title": "",
                        "student_count": 0,
                        "correct_count": 0,
                        "incorrect_count": 0,
                        "exercises": []
                    }
                ]
            },
            "periods": []
        }
    }
    </pre>
    #{json_schema(Api::V1::TaskPlanWithDetailedStatsRepresenter, include: :readable)}
  EOS
  def review
    plan = Tasks::Models::TaskPlan.preload_tasking_plans.find(params[:id])
    standard_read(plan, Api::V1::TaskPlanWithDetailedStatsRepresenter)
  end

  ###############################################################
  # destroy
  ###############################################################

  api :DELETE, '/plans/:id', 'Withdraws the specified TaskPlan'
  description <<-EOS
    Withdraws a task_plan from the teacher's course.

    Possible error code: task_plan_is_already_deleted

    #{json_schema(Api::V1::TaskPlanRepresenter, include: :readable)}
  EOS
  def destroy
    task_plan = Tasks::Models::TaskPlan.preload_tasking_plans.find(params[:id])
    standard_destroy(task_plan, Api::V1::TaskPlanRepresenter)
  end

  api :PUT, '/plans/:id/restore', 'Restores the specified TaskPlan'
  description <<-EOS
    Restores a task_plan to the teacher's course.

    Possible error code: task_plan_is_not_deleted

    #{json_schema(Api::V1::TaskPlanRepresenter, include: :readable)}
  EOS
  def restore
    task_plan = Tasks::Models::TaskPlan.preload_tasking_plans.find(params[:id])
    standard_restore(task_plan, Api::V1::TaskPlanRepresenter)
  end

  protected

  # Distributes or updates distributed tasks for the given task_plan
  # Returns the job uuid, if any, or nil if the request was completed inline
  def distribute_tasks(task_plan)
    preview_only = !task_plan.is_publish_requested && !task_plan.is_published?

    task_plan.publish_last_requested_at = Time.current \
      unless preview_only || task_plan.out_to_students?
    task_plan.save
    return if task_plan.errors.any?

    if preview_only
      # Task not published and publication not requested: preview only
      DistributeTasks.call(task_plan: task_plan, preview: true)
      nil
    else
      DistributeTasks.perform_later(task_plan: task_plan).tap do |job_uuid|
        task_plan.update_attribute(:publish_job_uuid, job_uuid)
      end
    end
  end
end
