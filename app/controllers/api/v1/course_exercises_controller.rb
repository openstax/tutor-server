class Api::V1::CourseExercisesController < Api::V1::ApiController

  before_filter :get_course

  resource_description do
    api_versions "v1"
    short_description 'Provides ways to get course exercises and set options on them'
    description <<-EOS
      Provides ways to get course exercises and set options on them
    EOS
  end

  api :GET, '/courses/:course_id/exercises',
            "Returns exercises for a given course, filtered by the page_ids param and optionally an array of pool_types"
  description <<-EOS
    Returns a list of exercises in the specified course associated with the pages with the given ID's and pool types.

    #{json_schema(Api::V1::ExerciseSearchRepresenter, include: :readable)}
  EOS
  def index
    OSU::AccessPolicy.require_action_allowed!(:exercises, current_api_user, @course)

    exercises = GetExercises[course: @course,
                             page_ids: params[:page_ids],
                             pool_types: params[:pool_types]]

    respond_with exercises, represent_with: Api::V1::ExerciseSearchRepresenter
  end

  api :PATCH, '/courses/:course_id/exercises/:exercise_id',
            "Updates the given exercise to be excluded or not for the given course"
  description <<-EOS
    Updates the given exercise to be excluded or not for the given course.

    #{json_schema(Api::V1::ExerciseSearchRepresenter, include: :writeable)}
  EOS
  def update
    OSU::AccessPolicy.require_action_allowed!(:exercises, current_api_user, @course)

    exercise_params = Hashie::Mash.new
    consume!(exercise_params, represent_with: Api::V1::ExerciseRepresenter)

    # TODO: make a routine?
    exercise = Content::Models::Exercise.find(params[:id])
    page_exercises = GetExercises[course: @course, page_ids: [exercise.page.id]]['items']
    exercise_representation = page_exercises.find{ |ex| ex['id'] == params[:id] }

    if exercise_params.is_excluded # true
      CourseContent::Models::ExcludedExercise.find_or_create_by(
        entity_course_id: @course.id, exercise_number: exercise.number
      )
      exercise_representation['is_excluded'] = true
    elsif !exercise_params.is_excluded.nil? # false
      excluded_exercise = CourseContent::Models::ExcludedExercise.find_by(
        entity_course_id: @course.id, exercise_number: exercise.number
      ).try(:destroy)
      exercise_representation['is_excluded'] = false
    end

    respond_with exercise_representation, represent_with: Api::V1::ExerciseRepresenter,
                                          responder: ResponderWithPutContent
  end

  protected

  def get_course
    @course = Entity::Course.find(params[:course_id])
  end

end
