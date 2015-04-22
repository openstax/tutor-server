class Api::V1::TaskPlansController < Api::V1::ApiController

  resource_description do
    api_versions "v1"
    short_description 'Represents a plan for a Task'
    description <<-EOS
      TaskPlans store information that assistants can use to generate Tasks.
    EOS
  end

  # TODO fix up the use of Tasks::Models throughout

  ###############################################################
  # show
  ###############################################################

  api :GET, '/plans/:id', "Retrieve a TaskPlan"
  description <<-EOS
   ### Example JSON response
   ```json
   {
     "id": 1,
     "type": "reading",
     "opens_at": "2015-03-10T21:29:35.260Z",
     "due_at": "2015-03-17T21:29:35.260Z",
     "settings": {}
   }
   ```
   #{json_schema(Api::V1::TaskPlanRepresenter, include: :readable)}
  EOS
  def show
    plan = Tasks::Models::TaskPlan.find(params[:id])
    standard_read(plan, Api::V1::TaskPlanRepresenter)
  end

  ###############################################################
  # post
  ###############################################################

  api :POST, '/courses/:course_id/plans', 'Creates a TaskPlan'
  description <<-EOS
    #{json_schema(Api::V1::TaskPlanRepresenter, include: :writeable)}
  EOS
  def create
    course = Entity::Course.find(params[:course_id])
    plan = BuildTaskPlan[course: course]
    standard_create(plan, Api::V1::TaskPlanRepresenter) do |tp|
      tp.assistant = Tasks::GetAssistant[course: course, task_plan: tp]
      return head :unprocessable_entity if tp.assistant.nil?
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
    task_plan = Tasks::Models::TaskPlan.find(params[:id])
    standard_update(task_plan, Api::V1::TaskPlanRepresenter)
  end

  ###############################################################
  # publish
  ###############################################################

  api :POST, '/plans/:id/publish', 'Publishes the specified TaskPlan'
  description <<-EOS
    #{json_schema(Api::V1::TaskPlanRepresenter, include: :writeable)}
  EOS
  def publish
    task_plan = Tasks::Models::TaskPlan.find(params[:id])
    OSU::AccessPolicy.require_action_allowed!(:publish,
                                              current_api_user,
                                              task_plan)
    DistributeTasks.call(task_plan)
    respond_with task_plan, represent_with: Api::V1::TaskPlanRepresenter, location: nil
  end

  ###############################################################
  # stats
  ###############################################################

  api :GET, '/plans/:id/stats', "Retrieve a TaskPlan along with its statistics"
  description <<-EOS
   ### Example JSON response
    ```{
      "id": 1, "type": "reading",
      "opens_at": "2015-03-10T21:29:35.260Z",
      "due_at": "2015-03-17T21:29:35.260Z",
      "stats": {
        "course": {
          "id": 1, "title": "My Course",
          "total_count": 36, "complete_count": 33, "partially_complete_count": 22,
          "current_pages": [
            {
              "correct_count": 27,"incorrect_count": 2,
              "page": { "id": 203, "number": "4.2", "title": "aggregate virtual bandwidth" }
            },{
              "correct_count": 23, "incorrect_count": 1,
              "page": { "id": 715, "number": "5.4", "title": "visualize back-end infrastructures" },
            }
          ],
          "spaced_pages": [
            {
              "correct_count": 26,"incorrect_count": 1,
              "page": { "id": 796, "number": "1.1", "title": "unleash global convergence" },
              "previous_attempt": {
                "correct_count": 13,"incorrect_count": 2
                "page": { "id": 924,"number": "5.1", "title": "unleash magnetic methodologies" }
              }
            }
          ]
        },
        "periods": [
          {
            "id": 1, "title": "MWF",
            "total_count": 23, "complete_count": 17, "partially_complete_count": 11,
            "current_pages": [
              {
                "correct_count": 16,"incorrect_count": 0,
                "page": {"id": 575,"number": "5.4","title": "scale out-of-the-box technologies" },
              }
            ]
          }
        ]
      }
    }```
    #{json_schema(Api::V1::TaskPlanWithStatsRepresenter, include: :readable)}
  EOS
  def stats
    plan = Tasks::Models::TaskPlan.find(params[:id])
    standard_read(plan, Api::V1::TaskPlanWithStatsRepresenter)
  end

  ###############################################################
  # review
  ###############################################################

  api :GET, '/plans/:id/review', "Retrieve a TaskPlan along with its detailed statistics"
  description <<-EOS
   ### Example JSON response
    ```{
      "id": 1, "type": "reading",
      "opens_at": "2015-03-10T21:29:35.260Z",
      "due_at": "2015-03-17T21:29:35.260Z",
      "stats": {
        "course": {
          "id": 1, "title": "My Course",
          "total_count": 36, "complete_count": 33, "partially_complete_count": 22,
          "current_pages": [
            {
              "correct_count": 27,"incorrect_count": 2,
              "page": { "id": 203, "number": "4.2", "title": "aggregate virtual bandwidth" }
            },{
              "correct_count": 23, "incorrect_count": 1,
              "page": { "id": 715, "number": "5.4", "title": "visualize back-end infrastructures" },
            }
          ],
          "spaced_pages": [
            {
              "correct_count": 26,"incorrect_count": 1,
              "page": { "id": 796, "number": "1.1", "title": "unleash global convergence" },
              "previous_attempt": {
                "correct_count": 13,"incorrect_count": 2
                "page": { "id": 924,"number": "5.1", "title": "unleash magnetic methodologies" }
              }
            }
          ]
        },
        "periods": [
          {
            "id": 1, "title": "MWF",
            "total_count": 23, "complete_count": 17, "partially_complete_count": 11,
            "current_pages": [
              {
                "correct_count": 16,"incorrect_count": 0,
                "page": {"id": 575,"number": "5.4","title": "scale out-of-the-box technologies" },
              }
            ]
          }
        ]
      }
    }```
    #{json_schema(Api::V1::TaskPlanWithDetailedStatsRepresenter, include: :readable)}
  EOS
  def review
    plan = Tasks::Models::TaskPlan.find(params[:id])
    standard_read(plan, Api::V1::TaskPlanWithDetailedStatsRepresenter)
  end

  ###############################################################
  # destroy
  ###############################################################

  api :DELETE, '/plans/:id', 'Deletes the specified TaskPlan'
  description <<-EOS
    #{json_schema(Api::V1::TaskPlanRepresenter, include: :writeable)}
  EOS
  def destroy
    task_plan = Tasks::Models::TaskPlan.find(params[:id])
    standard_destroy(task_plan)
  end

end
