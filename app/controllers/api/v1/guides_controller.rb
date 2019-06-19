module Api
  module V1
    class GuidesController < ApiController
      before_action :get_course
      before_action :error_if_student_and_needs_to_pay, only: [:student]

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
        # We don't use the get_course_role method when a role_id is given
        # because we allow teachers to look at any student's performance forecast
        # not just their own roles'
        # We trust the AccessPolicy for access control in this case
        role = if params[:role_id].blank?
          get_course_role(course: @course, allowed_role_types: [ :student, :teacher_student ])
        else
          Entity::Role.where(
            role_type: Entity::Role.role_types.values_at(:student, :teacher_student)
          ).find(params[:role_id])
        end

        OSU::AccessPolicy.require_action_allowed!(:show, current_api_user, role.course_member)

        guide = GetStudentGuide[role: role]
        respond_with guide, represent_with: Api::V1::CourseGuidePeriodRepresenter
      end

      api :GET, '/courses/:course_id/teacher_guide',
                'Returns course guide for Learning Guide for teachers'
      description <<-EOS
        #{json_schema(Api::V1::TeacherCourseGuideRepresenter, include: :readable)}
      EOS
      def teacher
        role = get_course_role(course: @course, allowed_role_types: :teacher)

        OSU::AccessPolicy.require_action_allowed!(:show, current_api_user, role.teacher)

        guide = GetTeacherGuide[role: role]
        respond_with guide, represent_with: Api::V1::TeacherCourseGuideRepresenter
      end

      protected

      def get_course
        @course = CourseProfile::Models::Course.find(params[:course_id])
      end

      def get_course_role(course:, allowed_role_types:)
        result = ChooseCourseRole.call(
          user: current_human_user, course: course,
          role_id: params[:role_id], allowed_role_types: allowed_role_types
        )
        raise(SecurityTransgression, :invalid_role) unless result.errors.empty?
        result.outputs.role
      end
    end
  end
end
