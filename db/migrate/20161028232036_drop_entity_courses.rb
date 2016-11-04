class DropEntityCourses < ActiveRecord::Migration
  def up
    # Prevent our records from potentially being deleted when Entity::Courses are gone
    remove_foreign_key :course_content_course_ecosystems, :entity_courses
    remove_foreign_key :course_membership_periods, :entity_courses
    remove_foreign_key :course_membership_students, :entity_courses
    remove_foreign_key :course_membership_teachers, :entity_courses
    remove_foreign_key :course_profile_courses, :entity_courses
    remove_foreign_key :tasks_course_assistants, :entity_courses
    remove_foreign_key :tasks_performance_report_exports, :entity_courses

    # Keep the old course IDs so we don't have to
    # change all the columns that used to point to entity_course_id
    CourseProfile::Models::Course.update_all('id = -id')
    CourseProfile::Models::Course.update_all('id = entity_course_id')

    rename_column :course_content_course_ecosystems, :entity_course_id, :course_profile_course_id
    rename_column :course_membership_students, :entity_course_id, :course_profile_course_id
    rename_column :course_membership_teachers, :entity_course_id, :course_profile_course_id
    rename_column :tasks_course_assistants, :entity_course_id, :course_profile_course_id

    # Avoid index name too long error
    remove_index :course_content_excluded_exercises, :entity_course_id
    rename_column :course_content_excluded_exercises, :entity_course_id, :course_profile_course_id
    add_index :course_content_excluded_exercises, :course_profile_course_id,
              name: 'index_c_c_excluded_exercises_on_c_p_course_id'

    # Avoid index name too long error
    remove_index :course_membership_periods, [:name, :entity_course_id]
    rename_column :course_membership_periods, :entity_course_id, :course_profile_course_id
    add_index :course_membership_periods, [:name, :course_profile_course_id],
              name: 'index_c_m_periods_on_name_and_c_p_course_id'

    # Avoid index name too long error
    remove_index :tasks_performance_report_exports, :entity_course_id
    rename_column :tasks_performance_report_exports, :entity_course_id, :course_profile_course_id
    add_index :tasks_performance_report_exports, :course_profile_course_id,
              name: 'index_t_performance_report_exports_on_c_p_course_id'

    # Change other columns that reference courses in a polymorphic way
    Tasks::Models::TaskPlan.where(owner_type: 'Entity::Course')
                           .update_all(owner_type: 'CourseProfile::Models::Course')
    Tasks::Models::TaskingPlan.where(target_type: 'Entity::Course')
                              .update_all(target_type: 'CourseProfile::Models::Course')
    Salesforce::Models::AttachedRecord.where{tutor_gid.like '%Entity::Course%'}.update_all(
      "tutor_gid = replace(tutor_gid, 'Entity::Course', 'CourseProfile::Models::Course')"
    )
    Legal::Models::TargetedContractRelationship.where do
      parent_gid.like '%Entity::Course%'
    end.update_all(
      "parent_gid = replace(parent_gid, 'Entity::Course', 'CourseProfile::Models::Course')"
    )
    Legal::Models::TargetedContractRelationship.where do
      child_gid.like '%Entity::Course%'
    end.update_all(
      "child_gid = replace(child_gid, 'Entity::Course', 'CourseProfile::Models::Course')"
    )

    remove_index :course_profile_courses, :entity_course_id
    remove_column :course_profile_courses, :entity_course_id
    drop_table :entity_courses

    add_foreign_key :course_content_course_ecosystems, :course_profile_courses,
                    on_update: :cascade, on_delete: :cascade
    add_foreign_key :course_content_excluded_exercises, :course_profile_courses,
                    on_update: :cascade, on_delete: :cascade
    add_foreign_key :course_membership_periods, :course_profile_courses,
                    on_update: :cascade, on_delete: :cascade
    add_foreign_key :course_membership_students, :course_profile_courses,
                    on_update: :cascade, on_delete: :cascade
    add_foreign_key :course_membership_teachers, :course_profile_courses,
                    on_update: :cascade, on_delete: :cascade
    add_foreign_key :tasks_course_assistants, :course_profile_courses,
                    on_update: :cascade, on_delete: :cascade
    add_foreign_key :tasks_performance_report_exports, :course_profile_courses,
                    on_update: :cascade, on_delete: :cascade
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
