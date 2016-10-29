class Api::V1::CourseExercisesController < Api::V1::ApiController

  before_filter :get_course

  resource_description do
    api_versions "v1"
    short_description 'Provides ways to get course exercises and set options on them'
    description <<-EOS
      Provides ways to get course exercises and set options on them
    EOS
  end

  api :GET, '/courses/:course_id/exercises(/:pool_types)',
            "Returns exercises for a given course's ecosystem, filtered by the following params: " +
            "ecosystem_id, page_ids, pool_types"
  description <<-EOS
    Returns a list of assignable exercises in the given course's ecosystem.
    Old ecosystems can be accessed by specifying the ecosystem_id param.
    The list is filtered by pages matching the given page_ids array
    and pools matching the given pool_types array, if given.
    Exercises are marked as excluded based on the given course.

    #{json_schema(Api::V1::ExerciseSearchRepresenter, include: :readable)}
  EOS
  def show
    ecosystem = params[:ecosystem_id].present? ? Content::Ecosystem.find(params[:ecosystem_id]) :
                                                 GetCourseEcosystem[course: @course]

    OSU::AccessPolicy.require_action_allowed!(:exercises, current_api_user, ecosystem)

    exercises = GetExercises[ecosystem: ecosystem,
                             course: @course,
                             page_ids: params[:page_ids],
                             pool_types: params[:pool_types]]

    respond_with exercises, represent_with: Api::V1::ExerciseSearchRepresenter
  end

  api :PATCH, '/courses/:course_id/exercises',
              "Updates the given exercise(s) to be excluded or not for the given course"
  description <<-EOS
    Updates the given exercise(s) to be excluded or not for the given course.

    #{json_schema(Api::V1::ExercisesRepresenter, include: :writeable)}
  EOS
  def update
    OSU::AccessPolicy.require_action_allowed!(:exercises, current_api_user, @course)

    exercise_params_array = []
    consume!(exercise_params_array, represent_with: Api::V1::ExercisesRepresenter)

    exercise_representations = CourseContent::UpdateExerciseExclusions[
      course: @course, updates_array: exercise_params_array
    ]

    respond_with exercise_representations, represent_with: Api::V1::ExercisesRepresenter,
                                           responder: ResponderWithPutPatchDeleteContent
  end

  protected

  def get_course
    @course = CourseProfile::Models::Course.find(params[:course_id])
  end

end
