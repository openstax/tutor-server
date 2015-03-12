class Api::V1::PlansController < Api::V1::ApiController


  ###############################################################
  # Show
  ###############################################################

  api :GET, '/plans/:id', "Retrieve a TaskPlan along with it's statistics"
  description <<-EOS
   ### Example JSON response
    ```{
      "id": 1, "type": "reading",
      "opens_at": "2015-03-10T21:29:35.260Z",
      "due_at": "2015-03-17T21:29:35.260Z",
      "settings": "{}"
      "stats": {
        "course": {
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
    #{json_schema(Api::V1::TaskPlanRepresenter, include: :readable)}
  EOS
  def show
    plan = TaskPlan.find(params[:id])
    stats = CalculateTaskPlanStatistics.call(plan:plan).outputs.statistics
    render json: Api::V1::TaskPlanRepresenter.new(plan).to_hash(stats: stats)
  end


end
