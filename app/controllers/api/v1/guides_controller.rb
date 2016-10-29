module Api
  module V1
    class GuidesController < ApiController
      resource_description do
        api_versions "v1"
        short_description 'Represents course guides in the system'
        description <<-EOS
          Course guide description to be written...
        EOS
      end

      api :GET, '/courses/:id/guide(/role/:role_id)',
                'Returns a student course guide for Learning Guide'
      description <<-EOS
        #{json_schema(Api::V1::CourseGuidePeriodRepresenter, include: :readable)}
      EOS
      def student
        course = CourseProfile::Models::Course.find(params[:id])
        guide = GetStudentGuide[role: role(course, :student)]
        respond_with guide, represent_with: Api::V1::CourseGuidePeriodRepresenter
      end

      api :GET, '/courses/:id/teacher_guide',
                'Returns course guide for Learning Guide for teachers'
      description <<-EOS
        #{json_schema(Api::V1::TeacherCourseGuideRepresenter, include: :readable)}
      EOS
      def teacher
        course = CourseProfile::Models::Course.find(params[:id])
        guide = GetTeacherGuide[role: role(course, :teacher)]
        respond_with guide, represent_with: Api::V1::TeacherCourseGuideRepresenter
      end

      private

      def role(course, types = :any)
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
