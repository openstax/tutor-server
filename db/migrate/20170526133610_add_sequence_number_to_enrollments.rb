class AddSequenceNumberToEnrollments < ActiveRecord::Migration
  def change
    add_column :course_membership_enrollments, :sequence_number, :integer

    reversible do |dir|
      dir.up do
        CourseMembership::Models::Enrollment.unscoped.update_all(
          <<-SQL.strip_heredoc
            "sequence_number" = "enrollments_with_sequence_numbers"."sequence_number"
            FROM (
              SELECT "course_membership_enrollments"."id", row_number() OVER (
                PARTITION BY "course_membership_student_id"
                ORDER BY "created_at"
              ) "sequence_number"
              FROM "course_membership_enrollments"
            ) "enrollments_with_sequence_numbers"
            WHERE "enrollments_with_sequence_numbers"."id" = "course_membership_enrollments"."id"
          SQL
        )
      end
    end

    change_column_null :course_membership_enrollments, :sequence_number, false

    remove_index :course_membership_enrollments,
                 column: [:course_membership_student_id, :created_at],
                 unique: true,
                 name: 'course_membership_enrollments_student_created_at_uniq'
    add_index :course_membership_enrollments,
              [:course_membership_student_id, :sequence_number],
              unique: true,
              name: 'index_enrollments_on_student_id_and_sequence_number'
  end
end
