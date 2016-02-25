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

    exercises = GetExercises[
      by: {
        course: @course,
        page_ids: params[:page_ids],
        pool_types: params[:pool_types]
      },
      with: :course_exercise_options
    ]

    exercise_hashes = exercises.collect do |_, exercise|
      Api::V1::ExerciseRepresenter.new(exercise).to_hash.tap do |hash|
        hash['pool_types'] = exercise['pool_types']
        hash['course_exercise_options'] = exercise['course_exercise_options']
      end
    end

    respond_with Hashie::Mash.new(items: exercise_hashes.values),
                 represent_with: Api::V1::ExerciseSearchRepresenter
  end

  def update
    OSU::AccessPolicy.require_action_allowed!(:exercises, current_api_user, @course)

    # TODO make routine that updates is_excluded, and if changed, changes pool in BL
    # TODO store the pool somewhere in Tutor - CourseContent::Models::ExclusionPool

    options = CourseContent::Models::ExerciseOptions.find_or_initialize_by(entity_course_id: @course.id, exercise_uid: params[:exercise_id])
    options.is_excluded = params[:is_excluded]

    options.save ?
      head(:success) :
      render_api_errors(options.errors)
  end

  protected

  def get_course
    @course = Entity::Course.find(params[:id] || params[:course_id])
  end

end
