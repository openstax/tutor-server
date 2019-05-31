class ChangeStudentIdentifierIndex < ActiveRecord::Migration[4.2]
  def change
    remove_index "course_membership_students",
                 column: ["entity_course_id", "student_identifier"],
                 name: "index_course_membership_students_on_e_c_id_and_s_identifier",
                 unique: true

    add_index "course_membership_students", ["entity_course_id", "student_identifier"],
              where: "deleted_at IS NULL",
              name: "index_course_membership_students_on_e_c_id_and_s_identifier",
              unique: true
  end
end
