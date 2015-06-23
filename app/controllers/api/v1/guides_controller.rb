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

      api :GET, '/courses/:id/guide',
                'Returns a student course guide for Learning Guide'
      description <<-EOS
        #{json_schema(Api::V1::CourseGuideRepresenter, include: :readable)}
      EOS
      def student
        course = Entity::Course.find(params[:id])
        role = get_course_role(types: :student)
        course_guide = GetCourseGuide[role: role, course: course]
        respond_with course_guide, represent_with: Api::V1::CourseGuideRepresenter
      end

      api :GET, '/courses/:id/teacher_guide(/role/:role_id)',
                'Returns course guide for Learning Guide for teachers'
      description <<-EOS
        #{json_schema(Api::V1::CourseGuideRepresenter, include: :readable)}
      EOS
      def teacher
        course = Entity::Course.find(params[:id])
        role = get_course_role(types: :teacher)
        course_guide = GetCourseGuide[role: role, course: course]
        respond_with course_guide, represent_with: Api::V1::CourseGuideRepresenter
      end

      private
      def get_course_role(types: :any)
        result = ChooseCourseRole.call(user: current_human_user.entity_user,
                                       course: Entity::Course.find(params[:id]),
                                       allowed_role_type: types,
                                       role_id: params[:role_id])
        if result.errors.any?
          raise(IllegalState, result.errors.map(&:message).to_sentence)
        end
        result.outputs.role
      end
    end
  end
end
