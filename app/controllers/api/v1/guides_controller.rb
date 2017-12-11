module Api
  module V1
    class GuidesController < ApiController
      before_filter :get_course
      before_filter :error_if_student_and_needs_to_pay, only: [:student]

      resource_description do
        api_versions "v1"
        short_description 'Represents course guides in the system'
        description <<-EOS
          Course guide description to be written...
        EOS
      end

      api :GET, '/courses/:course_id/guide(/role/:role_id)',
                'Returns a student course guide for Learning Guide'
      description <<-EOS
        #{json_schema(Api::V1::CourseGuidePeriodRepresenter, include: :readable)}
      EOS
      def student
        role = get_role(@course, :student)
        OSU::AccessPolicy.require_action_allowed!(:show, current_api_user, role.student)
        guide = GetStudentGuide[role: role]
        respond_with guide, represent_with: Api::V1::CourseGuidePeriodRepresenter
      end

      api :GET, '/courses/:course_id/teacher_guide',
                'Returns course guide for Learning Guide for teachers'
      description <<-EOS
        #{json_schema(Api::V1::TeacherCourseGuideRepresenter, include: :readable)}
      EOS
      def teacher
        role = get_role(@course, :teacher)
        OSU::AccessPolicy.require_action_allowed!(:show, current_api_user, role.teacher)
        guide = GetTeacherGuide[role: role]
        respond_with guide, represent_with: Api::V1::TeacherCourseGuideRepresenter
      end

      protected

      def get_course
        @course = CourseProfile::Models::Course.find(params[:course_id])
      end

      def get_role(course, types = :any)
        result = ChooseCourseRole.call(user: current_human_user,
                                       course: course,
                                       allowed_role_type: types,
                                       role_id: params[:role_id])
        if result.errors.any?
          raise(SecurityTransgression, :invalid_role)
        else
          result.outputs.role
        end
      end
    end
  end
end
