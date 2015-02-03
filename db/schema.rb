# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20141110212240) do

  create_table "administrators", force: true do |t|
    t.integer  "user_id",    null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_index "administrators", ["user_id"], name: "index_administrators_on_user_id", unique: true

  create_table "assistants", force: true do |t|
    t.integer  "study_id"
    t.string   "code_class_name", null: false
    t.text     "settings"
    t.text     "data"
    t.datetime "created_at",      null: false
    t.datetime "updated_at",      null: false
  end

  add_index "assistants", ["code_class_name"], name: "index_assistants_on_code_class_name"
  add_index "assistants", ["study_id"], name: "index_assistants_on_study_id"

  create_table "course_managers", force: true do |t|
    t.integer  "course_id",  null: false
    t.integer  "user_id",    null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_index "course_managers", ["course_id"], name: "index_course_managers_on_course_id"
  add_index "course_managers", ["user_id", "course_id"], name: "index_course_managers_on_user_id_and_course_id", unique: true

  create_table "courses", force: true do |t|
    t.string   "name"
    t.string   "short_name"
    t.text     "description"
    t.integer  "school_id"
    t.datetime "created_at",  null: false
    t.datetime "updated_at",  null: false
  end

  add_index "courses", ["name", "school_id"], name: "index_courses_on_name_and_school_id", unique: true
  add_index "courses", ["school_id"], name: "index_courses_on_school_id"
  add_index "courses", ["short_name", "school_id"], name: "index_courses_on_short_name_and_school_id", unique: true

  create_table "educators", force: true do |t|
    t.integer  "klass_id",   null: false
    t.integer  "user_id",    null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_index "educators", ["klass_id"], name: "index_educators_on_klass_id"
  add_index "educators", ["user_id", "klass_id"], name: "index_educators_on_user_id_and_klass_id", unique: true

  create_table "exercise_definition_topics", force: true do |t|
    t.integer  "exercise_definition_id", null: false
    t.integer  "topic_id",               null: false
    t.datetime "created_at",             null: false
    t.datetime "updated_at",             null: false
  end

  add_index "exercise_definition_topics", ["exercise_definition_id"], name: "index_exercise_definition_topics_on_exercise_definition_id"
  add_index "exercise_definition_topics", ["topic_id", "exercise_definition_id"], name: "index_ed_topics_on_topic_id_and_ed_id", unique: true

  create_table "exercise_definitions", force: true do |t|
    t.integer  "klass_id",   null: false
    t.string   "url"
    t.text     "content"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_index "exercise_definitions", ["klass_id", "url"], name: "index_exercise_definitions_on_klass_id_and_url", unique: true

  create_table "exercise_steps", force: true do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "fine_print_contracts", force: true do |t|
    t.string   "name",       null: false
    t.integer  "version"
    t.string   "title",      null: false
    t.text     "content",    null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_index "fine_print_contracts", ["name", "version"], name: "index_fine_print_contracts_on_name_and_version", unique: true

  create_table "fine_print_signatures", force: true do |t|
    t.integer  "contract_id", null: false
    t.integer  "user_id",     null: false
    t.string   "user_type",   null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "fine_print_signatures", ["contract_id"], name: "index_fine_print_signatures_on_contract_id"
  add_index "fine_print_signatures", ["user_id", "user_type", "contract_id"], name: "index_fine_print_signatures_on_u_id_and_u_type_and_c_id", unique: true

  create_table "interactive_steps", force: true do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "klasses", force: true do |t|
    t.integer  "course_id",                       null: false
    t.datetime "starts_at"
    t.datetime "ends_at"
    t.datetime "visible_at"
    t.datetime "invisible_at"
    t.string   "time_zone"
    t.text     "approved_emails"
    t.boolean  "allow_student_custom_identifier"
    t.datetime "created_at",                      null: false
    t.datetime "updated_at",                      null: false
  end

  add_index "klasses", ["course_id"], name: "index_klasses_on_course_id"
  add_index "klasses", ["ends_at"], name: "index_klasses_on_ends_at"
  add_index "klasses", ["invisible_at"], name: "index_klasses_on_invisible_at"
  add_index "klasses", ["starts_at"], name: "index_klasses_on_starts_at"
  add_index "klasses", ["visible_at"], name: "index_klasses_on_visible_at"

  create_table "oauth_access_grants", force: true do |t|
    t.integer  "resource_owner_id", null: false
    t.integer  "application_id",    null: false
    t.string   "token",             null: false
    t.integer  "expires_in",        null: false
    t.text     "redirect_uri",      null: false
    t.datetime "created_at",        null: false
    t.datetime "revoked_at"
    t.string   "scopes"
  end

  add_index "oauth_access_grants", ["token"], name: "index_oauth_access_grants_on_token", unique: true

  create_table "oauth_access_tokens", force: true do |t|
    t.integer  "resource_owner_id"
    t.integer  "application_id"
    t.string   "token",             null: false
    t.string   "refresh_token"
    t.integer  "expires_in"
    t.datetime "revoked_at"
    t.datetime "created_at",        null: false
    t.string   "scopes"
  end

  add_index "oauth_access_tokens", ["refresh_token"], name: "index_oauth_access_tokens_on_refresh_token", unique: true
  add_index "oauth_access_tokens", ["resource_owner_id"], name: "index_oauth_access_tokens_on_resource_owner_id"
  add_index "oauth_access_tokens", ["token"], name: "index_oauth_access_tokens_on_token", unique: true

  create_table "oauth_applications", force: true do |t|
    t.string   "name",         null: false
    t.string   "uid",          null: false
    t.string   "secret",       null: false
    t.text     "redirect_uri", null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "oauth_applications", ["uid"], name: "index_oauth_applications_on_uid", unique: true

  create_table "openstax_accounts_accounts", force: true do |t|
    t.integer  "openstax_uid", null: false
    t.string   "username",     null: false
    t.string   "access_token"
    t.string   "first_name"
    t.string   "last_name"
    t.string   "full_name"
    t.string   "title"
    t.datetime "created_at",   null: false
    t.datetime "updated_at",   null: false
  end

  add_index "openstax_accounts_accounts", ["access_token"], name: "index_openstax_accounts_accounts_on_access_token", unique: true
  add_index "openstax_accounts_accounts", ["first_name"], name: "index_openstax_accounts_accounts_on_first_name"
  add_index "openstax_accounts_accounts", ["full_name"], name: "index_openstax_accounts_accounts_on_full_name"
  add_index "openstax_accounts_accounts", ["last_name"], name: "index_openstax_accounts_accounts_on_last_name"
  add_index "openstax_accounts_accounts", ["openstax_uid"], name: "index_openstax_accounts_accounts_on_openstax_uid", unique: true
  add_index "openstax_accounts_accounts", ["username"], name: "index_openstax_accounts_accounts_on_username", unique: true

  create_table "openstax_accounts_group_members", force: true do |t|
    t.integer  "group_id",   null: false
    t.integer  "user_id",    null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_index "openstax_accounts_group_members", ["group_id", "user_id"], name: "index_openstax_accounts_group_members_on_group_id_and_user_id", unique: true
  add_index "openstax_accounts_group_members", ["user_id"], name: "index_openstax_accounts_group_members_on_user_id"

  create_table "openstax_accounts_group_nestings", force: true do |t|
    t.integer  "member_group_id",    null: false
    t.integer  "container_group_id", null: false
    t.datetime "created_at",         null: false
    t.datetime "updated_at",         null: false
  end

  add_index "openstax_accounts_group_nestings", ["container_group_id"], name: "index_openstax_accounts_group_nestings_on_container_group_id"
  add_index "openstax_accounts_group_nestings", ["member_group_id"], name: "index_openstax_accounts_group_nestings_on_member_group_id", unique: true

  create_table "openstax_accounts_group_owners", force: true do |t|
    t.integer  "group_id",   null: false
    t.integer  "user_id",    null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_index "openstax_accounts_group_owners", ["group_id", "user_id"], name: "index_openstax_accounts_group_owners_on_group_id_and_user_id", unique: true
  add_index "openstax_accounts_group_owners", ["user_id"], name: "index_openstax_accounts_group_owners_on_user_id"

  create_table "openstax_accounts_groups", force: true do |t|
    t.integer  "openstax_uid",                               null: false
    t.boolean  "is_public",                  default: false, null: false
    t.string   "name"
    t.text     "cached_subtree_group_ids"
    t.text     "cached_supertree_group_ids"
    t.datetime "created_at",                                 null: false
    t.datetime "updated_at",                                 null: false
  end

  add_index "openstax_accounts_groups", ["is_public"], name: "index_openstax_accounts_groups_on_is_public"
  add_index "openstax_accounts_groups", ["openstax_uid"], name: "index_openstax_accounts_groups_on_openstax_uid", unique: true

  create_table "reading_steps", force: true do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "resources", force: true do |t|
    t.string   "url"
    t.boolean  "is_immutable"
    t.text     "content"
    t.datetime "created_at",   null: false
    t.datetime "updated_at",   null: false
  end

  add_index "resources", ["url"], name: "index_resources_on_url", unique: true

  create_table "school_managers", force: true do |t|
    t.integer  "school_id",  null: false
    t.integer  "user_id",    null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_index "school_managers", ["school_id"], name: "index_school_managers_on_school_id"
  add_index "school_managers", ["user_id", "school_id"], name: "index_school_managers_on_user_id_and_school_id", unique: true

  create_table "schools", force: true do |t|
    t.string   "name"
    t.string   "default_time_zone"
    t.datetime "created_at",        null: false
    t.datetime "updated_at",        null: false
  end

  create_table "sections", force: true do |t|
    t.integer  "klass_id",   null: false
    t.string   "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_index "sections", ["klass_id"], name: "index_sections_on_klass_id"
  add_index "sections", ["name", "klass_id"], name: "index_sections_on_name_and_klass_id", unique: true

  create_table "students", force: true do |t|
    t.integer  "klass_id",                    null: false
    t.integer  "section_id"
    t.integer  "user_id",                     null: false
    t.integer  "level"
    t.boolean  "has_dropped"
    t.string   "student_custom_identifier"
    t.string   "educator_custom_identifier"
    t.string   "random_education_identifier", null: false
    t.datetime "created_at",                  null: false
    t.datetime "updated_at",                  null: false
  end

  add_index "students", ["educator_custom_identifier"], name: "index_students_on_educator_custom_identifier"
  add_index "students", ["klass_id"], name: "index_students_on_klass_id"
  add_index "students", ["level"], name: "index_students_on_level"
  add_index "students", ["random_education_identifier"], name: "index_students_on_random_education_identifier", unique: true
  add_index "students", ["section_id"], name: "index_students_on_section_id"
  add_index "students", ["student_custom_identifier"], name: "index_students_on_student_custom_identifier"
  add_index "students", ["user_id", "klass_id"], name: "index_students_on_user_id_and_klass_id", unique: true
  add_index "students", ["user_id", "section_id"], name: "index_students_on_user_id_and_section_id", unique: true

  create_table "task_plans", force: true do |t|
    t.integer  "assistant_id",                        null: false
    t.integer  "owner_id",                            null: false
    t.string   "owner_type",                          null: false
    t.string   "title"
    t.string   "type",                                null: false
    t.text     "configuration",                       null: false
    t.datetime "opens_at",                            null: false
    t.datetime "due_at"
    t.boolean  "invisible_until_open", default: true, null: false
    t.datetime "created_at",                          null: false
    t.datetime "updated_at",                          null: false
  end

  add_index "task_plans", ["assistant_id"], name: "index_task_plans_on_assistant_id"
  add_index "task_plans", ["due_at", "opens_at"], name: "index_task_plans_on_due_at_and_opens_at"
  add_index "task_plans", ["opens_at", "invisible_until_open"], name: "index_task_plans_on_opens_at_and_invisible_until_open"
  add_index "task_plans", ["owner_id", "owner_type"], name: "index_task_plans_on_owner_id_and_owner_type"

  create_table "task_steps", force: true do |t|
    t.integer  "details_id",   null: false
    t.string   "details_type", null: false
    t.integer  "resource_id",  null: false
    t.integer  "task_id",      null: false
    t.integer  "number",       null: false
    t.string   "title",        null: false
    t.datetime "created_at",   null: false
    t.datetime "updated_at",   null: false
  end

  add_index "task_steps", ["details_id", "details_type"], name: "index_task_steps_on_details_id_and_details_type", unique: true
  add_index "task_steps", ["resource_id"], name: "index_task_steps_on_resource_id"
  add_index "task_steps", ["task_id", "number"], name: "index_task_steps_on_task_id_and_number", unique: true
  add_index "task_steps", ["title"], name: "index_task_steps_on_title"

  create_table "tasking_plans", force: true do |t|
    t.integer  "target_id",    null: false
    t.string   "target_type",  null: false
    t.integer  "task_plan_id", null: false
    t.datetime "created_at",   null: false
    t.datetime "updated_at",   null: false
  end

  add_index "tasking_plans", ["target_id", "target_type", "task_plan_id"], name: "index_tasking_plans_on_t_id_and_t_type_and_t_p_id", unique: true
  add_index "tasking_plans", ["task_plan_id"], name: "index_tasking_plans_on_task_plan_id"

  create_table "taskings", force: true do |t|
    t.integer  "taskee_id",      null: false
    t.string   "taskee_type",    null: false
    t.integer  "task_id",        null: false
    t.integer  "user_id",        null: false
    t.integer  "grade_override"
    t.datetime "created_at",     null: false
    t.datetime "updated_at",     null: false
  end

  add_index "taskings", ["task_id", "user_id"], name: "index_taskings_on_task_id_and_user_id", unique: true
  add_index "taskings", ["taskee_id", "taskee_type", "task_id"], name: "index_taskings_on_taskee_id_and_taskee_type_and_task_id", unique: true
  add_index "taskings", ["user_id"], name: "index_taskings_on_user_id"

  create_table "tasks", force: true do |t|
    t.integer  "task_plan_id",               null: false
    t.string   "task_type",                  null: false
    t.string   "title",                      null: false
    t.datetime "opens_at",                   null: false
    t.datetime "due_at"
    t.integer  "taskings_count", default: 0, null: false
    t.datetime "created_at",                 null: false
    t.datetime "updated_at",                 null: false
  end

  add_index "tasks", ["due_at", "opens_at"], name: "index_tasks_on_due_at_and_opens_at"
  add_index "tasks", ["opens_at"], name: "index_tasks_on_opens_at"
  add_index "tasks", ["task_plan_id"], name: "index_tasks_on_task_plan_id"
  add_index "tasks", ["task_type"], name: "index_tasks_on_task_type"
  add_index "tasks", ["title"], name: "index_tasks_on_title"

  create_table "topics", force: true do |t|
    t.integer  "klass_id",   null: false
    t.string   "name",       null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_index "topics", ["klass_id", "name"], name: "index_topics_on_klass_id_and_name", unique: true

  create_table "users", force: true do |t|
    t.integer  "account_id",          null: false
    t.string   "exchange_identifier", null: false
    t.datetime "deleted_at"
    t.datetime "created_at",          null: false
    t.datetime "updated_at",          null: false
  end

  add_index "users", ["account_id"], name: "index_users_on_account_id", unique: true
  add_index "users", ["deleted_at"], name: "index_users_on_deleted_at"
  add_index "users", ["exchange_identifier"], name: "index_users_on_exchange_identifier", unique: true

end
