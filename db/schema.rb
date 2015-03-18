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

ActiveRecord::Schema.define(version: 20150313193101) do

  create_table "administrators", force: :cascade do |t|
    t.integer  "user_id",    null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_index "administrators", ["user_id"], name: "index_administrators_on_user_id", unique: true

  create_table "assistants", force: :cascade do |t|
    t.string   "name",            null: false
    t.string   "code_class_name", null: false
    t.string   "task_plan_type",  null: false
    t.datetime "created_at",      null: false
    t.datetime "updated_at",      null: false
  end

  add_index "assistants", ["code_class_name"], name: "index_assistants_on_code_class_name", unique: true
  add_index "assistants", ["name"], name: "index_assistants_on_name", unique: true

  create_table "content_book_parts", force: :cascade do |t|
    t.string   "url"
    t.text     "content"
    t.integer  "parent_book_part_id"
    t.integer  "entity_book_id"
    t.integer  "number",              null: false
    t.string   "title",               null: false
    t.string   "path"
    t.datetime "created_at",          null: false
    t.datetime "updated_at",          null: false
  end

  add_index "content_book_parts", ["entity_book_id"], name: "index_content_book_parts_on_entity_book_id"
  add_index "content_book_parts", ["parent_book_part_id", "number"], name: "index_content_book_parts_on_parent_book_part_id_and_number", unique: true
  add_index "content_book_parts", ["url"], name: "index_content_book_parts_on_url", unique: true

  create_table "content_exercise_topics", force: :cascade do |t|
    t.integer  "content_exercise_id", null: false
    t.integer  "content_topic_id",    null: false
    t.integer  "number",              null: false
    t.datetime "created_at",          null: false
    t.datetime "updated_at",          null: false
  end

  add_index "content_exercise_topics", ["content_exercise_id", "number"], name: "content_exercise_ce_number_unique", unique: true
  add_index "content_exercise_topics", ["content_topic_id", "content_exercise_id"], name: "content_exercise_topic_ce_unique", unique: true

  create_table "content_exercises", force: :cascade do |t|
    t.string   "url"
    t.text     "content"
    t.string   "title"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_index "content_exercises", ["title"], name: "index_content_exercises_on_title"
  add_index "content_exercises", ["url"], name: "index_content_exercises_on_url", unique: true

  create_table "content_page_topics", force: :cascade do |t|
    t.integer  "content_page_id",  null: false
    t.integer  "content_topic_id", null: false
    t.integer  "number",           null: false
    t.datetime "created_at",       null: false
    t.datetime "updated_at",       null: false
  end

  add_index "content_page_topics", ["content_page_id", "number"], name: "index_content_page_topics_on_content_page_id_and_number", unique: true
  add_index "content_page_topics", ["content_topic_id", "content_page_id"], name: "content_topic_page_ids_unique", unique: true

  create_table "content_pages", force: :cascade do |t|
    t.string   "url"
    t.text     "content"
    t.integer  "content_book_part_id"
    t.integer  "number",               null: false
    t.string   "title",                null: false
    t.string   "path"
    t.datetime "created_at",           null: false
    t.datetime "updated_at",           null: false
  end

  add_index "content_pages", ["content_book_part_id", "number"], name: "index_content_pages_on_content_book_part_id_and_number", unique: true
  add_index "content_pages", ["url"], name: "index_content_pages_on_url", unique: true

  create_table "content_topics", force: :cascade do |t|
    t.string   "name",        null: false
    t.text     "description"
    t.datetime "created_at",  null: false
    t.datetime "updated_at",  null: false
  end

  add_index "content_topics", ["name"], name: "index_content_topics_on_name", unique: true

  create_table "course_assistants", force: :cascade do |t|
    t.integer  "course_id",    null: false
    t.integer  "assistant_id", null: false
    t.text     "settings"
    t.text     "data"
    t.datetime "created_at",   null: false
    t.datetime "updated_at",   null: false
  end

  add_index "course_assistants", ["assistant_id"], name: "index_course_assistants_on_assistant_id"
  add_index "course_assistants", ["course_id", "assistant_id"], name: "index_course_assistants_on_course_id_and_assistant_id", unique: true

  create_table "course_content_course_books", force: :cascade do |t|
    t.integer  "entity_course_id", null: false
    t.integer  "entity_book_id",   null: false
    t.datetime "created_at",       null: false
    t.datetime "updated_at",       null: false
  end

  add_index "course_content_course_books", ["entity_book_id"], name: "index_course_content_course_books_on_entity_book_id"
  add_index "course_content_course_books", ["entity_course_id", "entity_book_id"], name: "[\"course_books_course_id_on_book_id_unique\"]", unique: true

  create_table "course_membership_students", force: :cascade do |t|
    t.integer  "entity_course_id", null: false
    t.integer  "entity_role_id",   null: false
    t.datetime "created_at",       null: false
    t.datetime "updated_at",       null: false
  end

  add_index "course_membership_students", ["entity_course_id", "entity_role_id"], name: "course_membership_student_course_role_uniq", unique: true

  create_table "course_membership_teachers", force: :cascade do |t|
    t.integer  "entity_course_id", null: false
    t.integer  "entity_role_id",   null: false
    t.datetime "created_at",       null: false
    t.datetime "updated_at",       null: false
  end

  add_index "course_membership_teachers", ["entity_course_id", "entity_role_id"], name: "course_membership_teacher_course_role_uniq", unique: true

  create_table "course_profile_profiles", force: :cascade do |t|
    t.integer  "entity_course_id", null: false
    t.string   "name",             null: false
    t.datetime "created_at",       null: false
    t.datetime "updated_at",       null: false
  end

  add_index "course_profile_profiles", ["entity_course_id"], name: "index_course_profile_profiles_on_entity_course_id", unique: true
  add_index "course_profile_profiles", ["name"], name: "index_course_profile_profiles_on_name"

  create_table "courses", force: :cascade do |t|
    t.string   "school",                          null: false
    t.string   "name",                            null: false
    t.string   "short_name",                      null: false
    t.string   "time_zone",                       null: false
    t.text     "description",                     null: false
    t.text     "approved_emails",                 null: false
    t.boolean  "allow_student_custom_identifier", null: false
    t.datetime "starts_at"
    t.datetime "ends_at"
    t.datetime "visible_at"
    t.datetime "invisible_at"
    t.datetime "created_at",                      null: false
    t.datetime "updated_at",                      null: false
  end

  add_index "courses", ["ends_at", "starts_at"], name: "index_courses_on_ends_at_and_starts_at"
  add_index "courses", ["invisible_at", "visible_at"], name: "index_courses_on_invisible_at_and_visible_at"
  add_index "courses", ["school", "name"], name: "index_courses_on_school_and_name", unique: true
  add_index "courses", ["short_name", "school"], name: "index_courses_on_short_name_and_school", unique: true

  create_table "educators", force: :cascade do |t|
    t.integer  "course_id",  null: false
    t.integer  "user_id",    null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_index "educators", ["course_id"], name: "index_educators_on_course_id"
  add_index "educators", ["user_id", "course_id"], name: "index_educators_on_user_id_and_course_id", unique: true

  create_table "entity_books", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "entity_courses", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "entity_roles", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "entity_users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "fine_print_contracts", force: :cascade do |t|
    t.string   "name",       null: false
    t.integer  "version"
    t.string   "title",      null: false
    t.text     "content",    null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_index "fine_print_contracts", ["name", "version"], name: "index_fine_print_contracts_on_name_and_version", unique: true

  create_table "fine_print_signatures", force: :cascade do |t|
    t.integer  "contract_id", null: false
    t.integer  "user_id",     null: false
    t.string   "user_type",   null: false
    t.datetime "created_at",  null: false
    t.datetime "updated_at",  null: false
  end

  add_index "fine_print_signatures", ["contract_id"], name: "index_fine_print_signatures_on_contract_id"
  add_index "fine_print_signatures", ["user_id", "user_type", "contract_id"], name: "index_fine_print_signatures_on_u_id_and_u_type_and_c_id", unique: true

  create_table "oauth_access_grants", force: :cascade do |t|
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

  create_table "oauth_access_tokens", force: :cascade do |t|
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

  create_table "oauth_applications", force: :cascade do |t|
    t.string   "name",         null: false
    t.string   "uid",          null: false
    t.string   "secret",       null: false
    t.text     "redirect_uri", null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "oauth_applications", ["uid"], name: "index_oauth_applications_on_uid", unique: true

  create_table "openstax_accounts_accounts", force: :cascade do |t|
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

  create_table "openstax_accounts_group_members", force: :cascade do |t|
    t.integer  "group_id",   null: false
    t.integer  "user_id",    null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_index "openstax_accounts_group_members", ["group_id", "user_id"], name: "index_openstax_accounts_group_members_on_group_id_and_user_id", unique: true
  add_index "openstax_accounts_group_members", ["user_id"], name: "index_openstax_accounts_group_members_on_user_id"

  create_table "openstax_accounts_group_nestings", force: :cascade do |t|
    t.integer  "member_group_id",    null: false
    t.integer  "container_group_id", null: false
    t.datetime "created_at",         null: false
    t.datetime "updated_at",         null: false
  end

  add_index "openstax_accounts_group_nestings", ["container_group_id"], name: "index_openstax_accounts_group_nestings_on_container_group_id"
  add_index "openstax_accounts_group_nestings", ["member_group_id"], name: "index_openstax_accounts_group_nestings_on_member_group_id", unique: true

  create_table "openstax_accounts_group_owners", force: :cascade do |t|
    t.integer  "group_id",   null: false
    t.integer  "user_id",    null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_index "openstax_accounts_group_owners", ["group_id", "user_id"], name: "index_openstax_accounts_group_owners_on_group_id_and_user_id", unique: true
  add_index "openstax_accounts_group_owners", ["user_id"], name: "index_openstax_accounts_group_owners_on_user_id"

  create_table "openstax_accounts_groups", force: :cascade do |t|
    t.integer  "openstax_uid",                               null: false
    t.boolean  "is_public",                  default: false, null: false
    t.string   "name"
    t.text     "cached_subtree_group_ids"
    t.text     "cached_supertree_group_ids"
    t.datetime "created_at",                                 null: false
    t.datetime "updated_at",                                 null: false
  end

  add_index "openstax_accounts_groups", ["openstax_uid"], name: "index_openstax_accounts_groups_on_openstax_uid", unique: true

  create_table "role_users", force: :cascade do |t|
    t.integer  "entity_user_id", null: false
    t.integer  "entity_role_id", null: false
    t.datetime "created_at",     null: false
    t.datetime "updated_at",     null: false
  end

  add_index "role_users", ["entity_user_id", "entity_role_id"], name: "role_users_user_role_uniq", unique: true

  create_table "sections", force: :cascade do |t|
    t.integer  "course_id",  null: false
    t.string   "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_index "sections", ["course_id"], name: "index_sections_on_course_id"
  add_index "sections", ["name", "course_id"], name: "index_sections_on_name_and_course_id", unique: true

  create_table "students", force: :cascade do |t|
    t.integer  "course_id",                   null: false
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

  add_index "students", ["course_id"], name: "index_students_on_course_id"
  add_index "students", ["educator_custom_identifier"], name: "index_students_on_educator_custom_identifier"
  add_index "students", ["level"], name: "index_students_on_level"
  add_index "students", ["random_education_identifier"], name: "index_students_on_random_education_identifier", unique: true
  add_index "students", ["section_id"], name: "index_students_on_section_id"
  add_index "students", ["student_custom_identifier"], name: "index_students_on_student_custom_identifier"
  add_index "students", ["user_id", "course_id"], name: "index_students_on_user_id_and_course_id", unique: true
  add_index "students", ["user_id", "section_id"], name: "index_students_on_user_id_and_section_id", unique: true

  create_table "task_plans", force: :cascade do |t|
    t.integer  "assistant_id", null: false
    t.integer  "owner_id",     null: false
    t.string   "owner_type",   null: false
    t.string   "title"
    t.string   "type",         null: false
    t.text     "settings",     null: false
    t.datetime "opens_at",     null: false
    t.datetime "due_at"
    t.datetime "created_at",   null: false
    t.datetime "updated_at",   null: false
  end

  add_index "task_plans", ["assistant_id"], name: "index_task_plans_on_assistant_id"
  add_index "task_plans", ["due_at", "opens_at"], name: "index_task_plans_on_due_at_and_opens_at"
  add_index "task_plans", ["owner_id", "owner_type"], name: "index_task_plans_on_owner_id_and_owner_type"

  create_table "task_steps", force: :cascade do |t|
    t.integer  "task_id",      null: false
    t.integer  "tasked_id",    null: false
    t.string   "tasked_type",  null: false
    t.integer  "number",       null: false
    t.datetime "completed_at"
    t.datetime "created_at",   null: false
    t.datetime "updated_at",   null: false
    t.integer  "page_id"
  end

  add_index "task_steps", ["task_id", "number"], name: "index_task_steps_on_task_id_and_number", unique: true
  add_index "task_steps", ["tasked_id", "tasked_type"], name: "index_task_steps_on_tasked_id_and_tasked_type", unique: true

  create_table "tasked_exercises", force: :cascade do |t|
    t.string   "url",           null: false
    t.text     "content",       null: false
    t.string   "title"
    t.text     "free_response"
    t.string   "answer_id"
    t.datetime "created_at",    null: false
    t.datetime "updated_at",    null: false
  end

  create_table "tasked_readings", force: :cascade do |t|
    t.string   "url",        null: false
    t.text     "content",    null: false
    t.string   "title"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "tasking_plans", force: :cascade do |t|
    t.integer  "target_id",    null: false
    t.string   "target_type",  null: false
    t.integer  "task_plan_id", null: false
    t.datetime "created_at",   null: false
    t.datetime "updated_at",   null: false
  end

  add_index "tasking_plans", ["target_id", "target_type", "task_plan_id"], name: "index_tasking_plans_on_t_id_and_t_type_and_t_p_id", unique: true
  add_index "tasking_plans", ["task_plan_id"], name: "index_tasking_plans_on_task_plan_id"

  create_table "taskings", force: :cascade do |t|
    t.integer  "taskee_id",   null: false
    t.string   "taskee_type", null: false
    t.integer  "task_id",     null: false
    t.integer  "user_id",     null: false
    t.datetime "created_at",  null: false
    t.datetime "updated_at",  null: false
  end

  add_index "taskings", ["task_id", "user_id"], name: "index_taskings_on_task_id_and_user_id", unique: true
  add_index "taskings", ["taskee_id", "taskee_type", "task_id"], name: "index_taskings_on_taskee_id_and_taskee_type_and_task_id", unique: true
  add_index "taskings", ["user_id"], name: "index_taskings_on_user_id"

  create_table "tasks", force: :cascade do |t|
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
  add_index "tasks", ["task_plan_id"], name: "index_tasks_on_task_plan_id"
  add_index "tasks", ["task_type"], name: "index_tasks_on_task_type"

  create_table "user_profile_profiles", force: :cascade do |t|
    t.integer  "entity_user_id",      null: false
    t.integer  "account_id",          null: false
    t.string   "exchange_identifier", null: false
    t.datetime "deleted_at"
    t.datetime "created_at",          null: false
    t.datetime "updated_at",          null: false
  end

  add_index "user_profile_profiles", ["account_id"], name: "index_user_profile_profiles_on_account_id", unique: true
  add_index "user_profile_profiles", ["deleted_at"], name: "index_user_profile_profiles_on_deleted_at"
  add_index "user_profile_profiles", ["exchange_identifier"], name: "index_user_profile_profiles_on_exchange_identifier", unique: true

end
