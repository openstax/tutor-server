class Api::V1::Research::Sparfa::TaskPlanRepresenter < Api::V1::Research::TaskPlanRepresenter
  collection :students,
             extend: Api::V1::Research::Sparfa::StudentRepresenter,
             getter: ->(user_options:, **) do
               students = CourseMembership::Models::Student.where(
                 id: tasks.preload(taskings: :role).flat_map do |task|
                   task.taskings.map { |tasking| tasking.role.course_membership_student_id }
                 end
               )

               user_options[:research_identifiers].nil? ? students : students.joins(:role).where(
                 role: { research_identifier: research_identifiers }
               )
             end,
             readable: true,
             writeable: false,
             schema_info: { required: true }

  property :ecosystem_matrix,
           extend: Api::V1::Research::Sparfa::EcosystemMatrixRepresenter,
           readable: true,
           writeable: false
end
