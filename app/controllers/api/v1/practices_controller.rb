module Api
  module V1
    class PracticesController < ApiController
      api :POST, '/courses/:course_id/practice(/role/:role_id)',
                 'Starts a new practice widget'
      description <<-EOS
        #{json_schema(Api::V1::PracticeRepresenter, include: :writeable)}
      EOS
      def create
        role = get_practice_role

        OSU::AccessPolicy.require_action_allowed!(:create_practice, current_human_user, @course)

        practice = OpenStruct.new
        consume!(practice, represent_with: Api::V1::PracticeRepresenter)

        result = ResetPracticeWidget.call(
          role: role, exercise_source: :biglearn,
          page_ids: practice.page_ids, chapter_ids: practice.chapter_ids
        )
        if result.errors.any?
          render_api_errors(result.errors)
        else
          respond_with result.outputs[:task],
                       represent_with: Api::V1::TaskRepresenter,
                       location: nil
        end
      end

      api :GET, '/courses/:course_id/practice(/role/:role_id)',
                'Gets the most recent practice widget'
      def show
        task = GetPracticeWidget[role: get_practice_role]

        task.nil? ? head(:not_found) :
                    respond_with(task, represent_with: Api::V1::TaskRepresenter)
      end

      protected

      def get_practice_role
        @course = Entity::Course.find(params[:id])
        result = ChooseCourseRole.call(user: current_human_user,
                                       course: @course,
                                       allowed_role_type: :student,
                                       role_id: params[:role_id])
        if result.errors.any?
          raise(SecurityTransgression, result.errors.map(&:message).to_sentence)
        else
          result.outputs.role
        end
      end
    end
  end
end
