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
  def show
    OSU::AccessPolicy.require_action_allowed!(:exercises, current_api_user, @course)

    exercises = GetExercises[course: @course,
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

    # TODO: make a routine
    page_ids = Content::Models::Exercise.find(exercise_params_array.map(&:id))
                                        .map(&:content_page_id)
    out = GetExercises.call(course: @course, page_ids: page_ids).outputs
    exercises = out.exercises.index_by{ |ex| ex.id.to_s }
    page_exercises = out.exercise_search['items'].index_by(&:id)

    exercise_representations = exercise_params_array.map do |exercise_params|
      exercise = exercises[exercise_params.id]
      exercise_representation = page_exercises[exercise_params.id]

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

      exercise_representation
    end

    # Create a new Biglearn excluded pool for the course
    excluded_exercise_numbers = CourseContent::Models::ExcludedExercise
                                  .where(entity_course_id: @course.id).pluck(:exercise_number)
    exercises_base_url = Addressable::URI.parse(OpenStax::Exercises::V1.server_url)
    exercises_base_url.scheme = nil
    exercises_base_url.path = 'exercises'
    excluded_exercise_question_ids = excluded_exercise_numbers.map do |number|
      "#{exercises_base_url}/#{number}"
    end
    bl_excluded_exercises = excluded_exercise_question_ids.map do |question_id|
      # version 1 is the default according to the Biglearn API docs...
      # If we need to track it, we might need an extra field in ExcludedExercise,
      # or switch to using the Content::Models::Exercise id
      OpenStax::Biglearn::V1::Exercise.new(question_id: question_id, version: 1, tags: [])
    end
    bl_excluded_pool = OpenStax::Biglearn::V1::Pool.new(exercises: bl_excluded_exercises)
    bl_excluded_pool_with_uuid = OpenStax::Biglearn::V1.add_pools([bl_excluded_pool]).first
    @course.profile.update_attribute(:biglearn_excluded_pool_uuid, bl_excluded_pool_with_uuid.uuid)
    # TODO: end routine

    respond_with exercise_representations, represent_with: Api::V1::ExercisesRepresenter,
                                           responder: ResponderWithPutContent
  end

  protected

  def get_course
    @course = Entity::Course.find(params[:course_id])
  end

end
