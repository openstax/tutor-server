class Api::V1::EcosystemsController < Api::V1::ApiController

  resource_description do
    api_versions "v1"
    short_description 'Provides ways to retrieve content such as books and exercises'
    description <<-EOS
      Provides ways to retrieve content such as books and exercises
      Content can be retrieved either by course id or by ecosystem id
    EOS
  end

  api :GET, '/ecosystems', 'Returns all available ecosystems'
  description <<-EOS
    Returns a listing of all the ecosytems that exist in Tutor

    #{json_schema(Api::V1::EcosystemsRepresenter, include: :readable)}
  EOS
  def index
    OSU::AccessPolicy.require_action_allowed!(:index, current_human_user, Content::Models::Ecosystem)
    ecosystems = Content::ListEcosystems[]
    respond_with ecosystems, represent_with: Api::V1::EcosystemsRepresenter
  end

  api :GET, '/ecosystems/:ecosystem_id/readings', 'Returns readings for a given ecosystem'
  description <<-EOS
    Returns a hierarchical listing of an ecosystem's readings.
    An ecosystem is currently limited to only one book.
    Inside each book there can be units, chapters and pages.

    #{json_schema(Api::V1::BookTocsRepresenter, include: :readable)}
  EOS
  def readings
    ecosystem = ::Content::Models::Ecosystem.find(params[:id])

    OSU::AccessPolicy.require_action_allowed!(:readings, current_api_user, ecosystem)

    render(
      json: Rails.cache.fetch(ecosystem.cache_key, version: ecosystem.cache_version) do
        # For the moment, we're assuming just one book per ecosystem
        books = ecosystem.books
        raise NotYetImplemented if books.count > 1

        Api::V1::BookTocsRepresenter.new(books).to_json
      end
    ) if stale?(ecosystem, template: false)
  end

  api :GET, '/ecosystems/:ecosystem_id/exercises(/:pool_types)',
            'Returns exercises for a given ecosystem, filtered by the following params: ' +
            'course_id, page_ids, exercise_ids, pool_types'
  description <<-EOS
    Returns a list of assignable exercises in the given ecosystem.
    The list is filtered by pages matching the given page_ids array
    and pools matching the given pool_types array, if given.
    Exercises are marked as excluded based on the course_id param, if given.

    #{json_schema(Api::V1::ExerciseSearchRepresenter, include: :readable)}
  EOS
  def exercises
    ecosystem = ::Content::Models::Ecosystem.find(params[:id])
    course = CourseProfile::Models::Course.find(params[:course_id]) if params[:course_id].present?

    if current_human_user.account.student?
      role = ChooseCourseRole.call(user: current_human_user,
                                   course: [course],
                                   role_id: params[:role_id],
                                   allowed_role_types: [ :student, :teacher_student ]).outputs.role

      exercise_ids = role.practice_questions.where(content_exercise_id: params[:exercise_ids]).pluck(:content_exercise_id)

      exercises = GetExercises.call(ecosystem: ecosystem,
                                    course: course,
                                    exercise_ids: exercise_ids).outputs.exercises

      respond_with(exercises,
                   represent_with: Api::V1::ExerciseSearchRepresenter,
                   user_options: { for_student: true }) and return

    else
      OSU::AccessPolicy.require_action_allowed!(:exercises, current_api_user, ecosystem)

      exercises = GetExercises[ecosystem: ecosystem,
                               course: course,
                               exercise_ids: params[:exercise_ids],
                               page_ids: params[:page_ids],
                               pool_types: params[:pool_types]]
    end

    respond_with exercises, represent_with: Api::V1::ExerciseSearchRepresenter, user_options: { for_student: false }
  end

end
