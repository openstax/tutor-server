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
        #{json_schema(Api::V1::CourseGuideRepresenter, include: :readable)}
      EOS
      def student
        course = Entity::Course.find(params[:id])
        guide = GetCourseGuide[role: role(course, :student), course: course]
        respond_with guide, represent_with: Api::V1::CourseGuideRepresenter
      end

      api :GET, '/courses/:id/teacher_guide',
                'Returns course guide for Learning Guide for teachers'
      description <<-EOS
        #{json_schema(Api::V1::CourseGuideRepresenter, include: :readable)}
      EOS
      def teacher
        course = Entity::Course.find(params[:id])
        guide = GetCourseGuide[role: role(course, :teacher), course: course]
        respond_with guide, represent_with: Api::V1::CourseGuideRepresenter
      end

      private
      def role(course, types = :any)
        result = ChooseCourseRole.call(user: current_human_user.entity_user,
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
