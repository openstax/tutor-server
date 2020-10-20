module Api::V1
  class PracticesController < ApiController
    before_action :get_course_and_practice_role
    before_action :error_if_student_and_needs_to_pay, only: [:create, :create_worst, :create_saved, :show]

    api :POST, '/courses/:course_id/practice',
               'Starts a new practice widget for a specific set of page_ids'
    description <<-EOS
      #{json_schema(Api::V1::PracticeRepresenter, include: :writeable)}
    EOS
    def create
      OSU::AccessPolicy.require_action_allowed!(:create_practice, current_human_user, @course)

      practice = OpenStruct.new
      consume!(practice, represent_with: Api::V1::PracticeRepresenter)

      result = FindOrCreatePracticeSpecificTopicsTask.call(
        course: @course, role: @role, page_ids: practice.page_ids
      )

      render_api_errors(result.errors) || respond_with(
        result.outputs.task,
        represent_with: Api::V1::TaskRepresenter,
        location: nil
      )
    end

    api :POST, '/courses/:course_id/practice/worst',
               'Starts a new practice widget for Practice Worst Topics'
    def create_worst
      OSU::AccessPolicy.require_action_allowed!(:create_practice, current_human_user, @course)

      result = FindOrCreatePracticeWorstTopicsTask.call course: @course, role: @role

      render_api_errors(result.errors) || respond_with(
        result.outputs.task,
        represent_with: Api::V1::TaskRepresenter,
        location: nil
      )
    end

    api :GET, '/courses/:course_id/practice/saved',
              'Returns the id of an existing practice that was created from saved PracticeQuestions'
    def find_saved
      OSU::AccessPolicy.require_action_allowed!(:create_practice, current_human_user, @course)

      # Find a not completed practice task
      task = ::Tasks::GetPracticeTask[
        role: @role,
        task_type: :practice_saved
      ]

      render json: { id: task&.id }
    end

    api :POST, '/courses/:course_id/practice/saved',
               'Starts a new practice from saved PracticeQuestions'
    def create_saved
      OSU::AccessPolicy.require_action_allowed!(:create_practice, current_human_user, @course)

      result = FindOrCreatePracticeSavedTask.call(
        course: @course, role: @role, question_ids: params[:practice_question_ids]
      )

      render_api_errors(result.errors) || respond_with(
        result.outputs.task,
        represent_with: Api::V1::TaskRepresenter,
        location: nil
      )
    end

    api :PUT, '/courses/:course_id/practice/:id/exit',
               'Exits and completes a practice'
    def exit
      OSU::AccessPolicy.require_action_allowed!(:create_practice, current_human_user, @course)

      task = ::Tasks::GetPracticeTask[
        id: params[:id],
        role: @role,
        task_type: [:practice_saved, :practice_worst_topics, :chapter_practice, :page_practice]
      ]

      respond_with(
        task,
        represent_with: Api::V1::TaskRepresenter,
        location: nil
      )
    end

    protected

    def get_course_and_practice_role
      @course = CourseProfile::Models::Course.find(params[:course_id])
      result = ChooseCourseRole.call(user: current_human_user,
                                     course: @course,
                                     role_id: params[:role_id],
                                     allowed_role_types: [ :student, :teacher_student ])
      if result.errors.any?
        raise(SecurityTransgression, result.errors.map(&:message).to_sentence)
      else
        @role = result.outputs.role
      end
    end
  end
end
