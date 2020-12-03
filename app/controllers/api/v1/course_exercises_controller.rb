class Api::V1::CourseExercisesController < Api::V1::ApiController

  before_action :get_course

  resource_description do
    api_versions "v1"
    short_description 'Provides ways to create and exclude exercises for the given course'
  end

  api :POST, '/courses/:course_id/exercises',
              "Creates an exercise"
  description <<-EOS
    Creates an exercise.

    #{json_schema(Api::V1::ExerciseRepresenter, include: :writeable)}
  EOS
  def create
    OSU::AccessPolicy.require_action_allowed!(:exercises, current_api_user, @course)

    page    = @course.ecosystem.pages.find(params[:selectedChapterSection])
    content = BuildTeacherExerciseContentHash[data: params]
    profile = @course.teachers.map{|t| t.role.profile }.find{|p| p.id == params[:authorId] } || current_human_user
    params.permit(:images)

    exercise = CreateTeacherExercise[
      course: @course,
      page: page,
      content: content,
      images: params[:images],
      profile: profile,
      derived_from_id: params[:derived_from_id],
      anonymize: params[:anonymize],
      copyable:  params[:copyable],
      save: true
    ]

    respond_with exercise, represent_with: Api::V1::ExerciseRepresenter,
                           responder: ResponderWithPutPatchDeleteContent,
                           location: nil
  end

  api :PATCH, '/courses/:course_id/exercises/exclude',
              "Updates the given exercise(s) to be excluded or not for the given course"
  description <<-EOS
    Updates the given exercise(s) to be excluded or not for the given course.

    #{json_schema(Api::V1::ExercisesRepresenter, include: :writeable)}
  EOS
  def exclude
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
