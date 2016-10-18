class AddEntityTeacherStudentRoleIdToPeriods < ActiveRecord::Migration
  def change
    add_column :course_membership_periods, :entity_teacher_student_role_id, :integer

    reversible do |dir|
      dir.up do
        print "\nMigrating #{CourseMembership::Models::Period.with_deleted.count} periods"

        CourseMembership::Models::Period.with_deleted.find_each do |period|
          teacher_student_role = Entity::Role.create!(role_type: :teacher_student)
          period.update_attribute :entity_teacher_student_role_id, teacher_student_role.id
          ReassignPublishedPeriodTaskPlans[period: period]
          print '.'
        end

        print "\n\n"
      end
    end

    change_column_null :course_membership_periods, :entity_teacher_student_role_id, false
    add_index :course_membership_periods, :entity_teacher_student_role_id, unique: true,
              name: 'index_c_m_periods_on_e_teacher_student_role_id'
  end
end
