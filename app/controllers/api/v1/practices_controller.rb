module Api
  module V1
    class PracticesController < ApiController
      api :POST, '/courses/:course_id/practice(/role/:role_id)',
                 'Starts a new practice widget for a specific set of page_ids or chapter_ids'
      description <<-EOS
        #{json_schema(Api::V1::PracticeRepresenter, include: :writeable)}
      EOS
      def create_specific
        course, role = get_practice_course_and_role

        OSU::AccessPolicy.require_action_allowed!(:create_practice, current_human_user, course)

        practice = OpenStruct.new
        consume!(practice, represent_with: Api::V1::PracticeRepresenter)

        result = CreatePracticeSpecificTopicsTask.call(
          course: course, role: role, page_ids: practice.page_ids, chapter_ids: practice.chapter_ids
        )

        task = result.outputs.task

        task = ::Tasks::PopulatePlaceholderSteps.call(task: task).outputs.task

        if task.task_steps.empty?
          render_api_errors(
            [
              {
                code: :no_exercises,
                message: "No exercises were returned from Biglearn to build the Practice Widget." +
                         " [Course: #{course.id} - Role: #{role.id}" +
                         " - Task Type: #{task.task_type} - Ecosystem: #{task.ecosystem.title}]"
              }
            ]
          )
        else
          respond_with(
            task,
            represent_with: Api::V1::TaskRepresenter,
            location: nil
          )
        end
      end

      api :POST, '/courses/:course_id/practice/worst(/role/:role_id)',
                 'Starts a new practice widget for Practice Worst Topics'
      def create_worst
        course, role = get_practice_course_and_role

        OSU::AccessPolicy.require_action_allowed!(:create_practice, current_human_user, course)

        result = CreatePracticeWorstTopicsTask.call course: course, role: role

        errors = result.outputs.errors || result.errors
        render_api_errors(errors) || respond_with(
          result.outputs.task,
          represent_with: Api::V1::TaskRepresenter,
          location: nil
        )
      end

      api :GET, '/courses/:course_id/practice(/role/:role_id)',
                'Gets the most recent practice widget'
      def show
        course, role = get_practice_course_and_role
        task = ::Tasks::GetPracticeTask[role: role]

        task.nil? ? head(:not_found) : respond_with(task, represent_with: Api::V1::TaskRepresenter)
      end

      protected

      def get_practice_course_and_role
        course = CourseProfile::Models::Course.find(params[:id])
        result = ChooseCourseRole.call(user: current_human_user,
                                       course: course,
                                       allowed_role_type: :student,
                                       role_id: params[:role_id])
        if result.errors.any?
          raise(SecurityTransgression, result.errors.map(&:message).to_sentence)
        else
          [course, result.outputs.role]
        end
      end
    end
  end
end
