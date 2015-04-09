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

ActiveRecord::Schema.define(version: 20150406200833) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "administrators", force: :cascade do |t|
    t.integer  "profile_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_index "administrators", ["profile_id"], name: "index_administrators_on_profile_id", unique: true, using: :btree

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

  add_index "content_book_parts", ["entity_book_id"], name: "index_content_book_parts_on_entity_book_id", using: :btree
  add_index "content_book_parts", ["parent_book_part_id", "number"], name: "index_content_book_parts_on_parent_book_part_id_and_number", unique: true, using: :btree
  add_index "content_book_parts", ["url"], name: "index_content_book_parts_on_url", unique: true, using: :btree

  create_table "content_exercise_tags", force: :cascade do |t|
    t.integer  "content_exercise_id", null: false
    t.integer  "content_tag_id",      null: false
    t.datetime "created_at",          null: false
    t.datetime "updated_at",          null: false
  end

  add_index "content_exercise_tags", ["content_exercise_id", "content_tag_id"], name: "index_content_exercise_tags_on_c_e_id_and_c_t_id", unique: true, using: :btree
  add_index "content_exercise_tags", ["content_tag_id"], name: "index_content_exercise_tags_on_content_tag_id", using: :btree

  create_table "content_exercises", force: :cascade do |t|
    t.string   "url"
    t.text     "content"
    t.string   "title"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_index "content_exercises", ["title"], name: "index_content_exercises_on_title", using: :btree
  add_index "content_exercises", ["url"], name: "index_content_exercises_on_url", unique: true, using: :btree

  create_table "content_page_tags", force: :cascade do |t|
    t.integer  "content_page_id", null: false
    t.integer  "content_tag_id",  null: false
    t.datetime "created_at",      null: false
    t.datetime "updated_at",      null: false
  end

  add_index "content_page_tags", ["content_page_id", "content_tag_id"], name: "index_content_page_tags_on_content_page_id_and_content_tag_id", unique: true, using: :btree
  add_index "content_page_tags", ["content_tag_id"], name: "index_content_page_tags_on_content_tag_id", using: :btree

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

  add_index "content_pages", ["content_book_part_id", "number"], name: "index_content_pages_on_content_book_part_id_and_number", unique: true, using: :btree
  add_index "content_pages", ["url"], name: "index_content_pages_on_url", unique: true, using: :btree

  create_table "content_tags", force: :cascade do |t|
    t.string   "name",                    null: false
    t.integer  "tag_type",    default: 0, null: false
    t.text     "description"
    t.datetime "created_at",              null: false
    t.datetime "updated_at",              null: false
  end

  add_index "content_tags", ["name"], name: "index_content_tags_on_name", unique: true, using: :btree
  add_index "content_tags", ["tag_type"], name: "index_content_tags_on_tag_type", using: :btree

  create_table "course_content_course_books", force: :cascade do |t|
    t.integer  "entity_course_id", null: false
    t.integer  "entity_book_id",   null: false
    t.datetime "created_at",       null: false
    t.datetime "updated_at",       null: false
  end

  add_index "course_content_course_books", ["entity_book_id"], name: "index_course_content_course_books_on_entity_book_id", using: :btree
  add_index "course_content_course_books", ["entity_course_id", "entity_book_id"], name: "[\"course_books_course_id_on_book_id_unique\"]", unique: true, using: :btree

  create_table "course_membership_students", force: :cascade do |t|
    t.integer  "entity_course_id", null: false
    t.integer  "entity_role_id",   null: false
    t.datetime "created_at",       null: false
    t.datetime "updated_at",       null: false
  end

  add_index "course_membership_students", ["entity_course_id", "entity_role_id"], name: "course_membership_student_course_role_uniq", unique: true, using: :btree

  create_table "course_membership_teachers", force: :cascade do |t|
    t.integer  "entity_course_id", null: false
    t.integer  "entity_role_id",   null: false
    t.datetime "created_at",       null: false
    t.datetime "updated_at",       null: false
  end

  add_index "course_membership_teachers", ["entity_course_id", "entity_role_id"], name: "course_membership_teacher_course_role_uniq", unique: true, using: :btree

  create_table "course_profile_profiles", force: :cascade do |t|
    t.integer  "entity_course_id", null: false
    t.string   "name",             null: false
    t.datetime "created_at",       null: false
    t.datetime "updated_at",       null: false
  end

  add_index "course_profile_profiles", ["entity_course_id"], name: "index_course_profile_profiles_on_entity_course_id", unique: true, using: :btree
  add_index "course_profile_profiles", ["name"], name: "index_course_profile_profiles_on_name", using: :btree

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

  add_index "courses", ["ends_at", "starts_at"], name: "index_courses_on_ends_at_and_starts_at", using: :btree
  add_index "courses", ["invisible_at", "visible_at"], name: "index_courses_on_invisible_at_and_visible_at", using: :btree
  add_index "courses", ["school", "name"], name: "index_courses_on_school_and_name", unique: true, using: :btree
  add_index "courses", ["short_name", "school"], name: "index_courses_on_short_name_and_school", unique: true, using: :btree

  create_table "educators", force: :cascade do |t|
    t.integer  "course_id",  null: false
    t.integer  "user_id",    null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_index "educators", ["course_id"], name: "index_educators_on_course_id", using: :btree
  add_index "educators", ["user_id", "course_id"], name: "index_educators_on_user_id_and_course_id", unique: true, using: :btree

  create_table "entity_books", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "entity_courses", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "entity_roles", force: :cascade do |t|
    t.integer  "role_type",  default: 0, null: false
    t.datetime "created_at",             null: false
    t.datetime "updated_at",             null: false
  end

  add_index "entity_roles", ["role_type"], name: "index_entity_roles_on_role_type", using: :btree

  create_table "entity_tasks", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "entity_users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "fake_stores", force: :cascade do |t|
    t.text     "data"
    t.string   "name",       null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_index "fake_stores", ["name"], name: "index_fake_stores_on_name", unique: true, using: :btree

  create_table "fine_print_contracts", force: :cascade do |t|
    t.string   "name",       null: false
    t.integer  "version"
    t.string   "title",      null: false
    t.text     "content",    null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_index "fine_print_contracts", ["name", "version"], name: "index_fine_print_contracts_on_name_and_version", unique: true, using: :btree

  create_table "fine_print_signatures", force: :cascade do |t|
    t.integer  "contract_id", null: false
    t.integer  "user_id",     null: false
    t.string   "user_type",   null: false
    t.datetime "created_at",  null: false
    t.datetime "updated_at",  null: false
  end

  add_index "fine_print_signatures", ["contract_id"], name: "index_fine_print_signatures_on_contract_id", using: :btree
  add_index "fine_print_signatures", ["user_id", "user_type", "contract_id"], name: "index_fine_print_signatures_on_u_id_and_u_type_and_c_id", unique: true, using: :btree

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

  add_index "oauth_access_grants", ["token"], name: "index_oauth_access_grants_on_token", unique: true, using: :btree

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

  add_index "oauth_access_tokens", ["refresh_token"], name: "index_oauth_access_tokens_on_refresh_token", unique: true, using: :btree
  add_index "oauth_access_tokens", ["resource_owner_id"], name: "index_oauth_access_tokens_on_resource_owner_id", using: :btree
  add_index "oauth_access_tokens", ["token"], name: "index_oauth_access_tokens_on_token", unique: true, using: :btree

  create_table "oauth_applications", force: :cascade do |t|
    t.string   "name",                      null: false
    t.string   "uid",                       null: false
    t.string   "secret",                    null: false
    t.text     "redirect_uri",              null: false
    t.string   "scopes",       default: "", null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "oauth_applications", ["uid"], name: "index_oauth_applications_on_uid", unique: true, using: :btree

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

  add_index "openstax_accounts_accounts", ["access_token"], name: "index_openstax_accounts_accounts_on_access_token", unique: true, using: :btree
  add_index "openstax_accounts_accounts", ["first_name"], name: "index_openstax_accounts_accounts_on_first_name", using: :btree
  add_index "openstax_accounts_accounts", ["full_name"], name: "index_openstax_accounts_accounts_on_full_name", using: :btree
  add_index "openstax_accounts_accounts", ["last_name"], name: "index_openstax_accounts_accounts_on_last_name", using: :btree
  add_index "openstax_accounts_accounts", ["openstax_uid"], name: "index_openstax_accounts_accounts_on_openstax_uid", unique: true, using: :btree
  add_index "openstax_accounts_accounts", ["username"], name: "index_openstax_accounts_accounts_on_username", unique: true, using: :btree

  create_table "openstax_accounts_group_members", force: :cascade do |t|
    t.integer  "group_id",   null: false
    t.integer  "user_id",    null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_index "openstax_accounts_group_members", ["group_id", "user_id"], name: "index_openstax_accounts_group_members_on_group_id_and_user_id", unique: true, using: :btree
  add_index "openstax_accounts_group_members", ["user_id"], name: "index_openstax_accounts_group_members_on_user_id", using: :btree

  create_table "openstax_accounts_group_nestings", force: :cascade do |t|
    t.integer  "member_group_id",    null: false
    t.integer  "container_group_id", null: false
    t.datetime "created_at",         null: false
    t.datetime "updated_at",         null: false
  end

  add_index "openstax_accounts_group_nestings", ["container_group_id"], name: "index_openstax_accounts_group_nestings_on_container_group_id", using: :btree
  add_index "openstax_accounts_group_nestings", ["member_group_id"], name: "index_openstax_accounts_group_nestings_on_member_group_id", unique: true, using: :btree

  create_table "openstax_accounts_group_owners", force: :cascade do |t|
    t.integer  "group_id",   null: false
    t.integer  "user_id",    null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_index "openstax_accounts_group_owners", ["group_id", "user_id"], name: "index_openstax_accounts_group_owners_on_group_id_and_user_id", unique: true, using: :btree
  add_index "openstax_accounts_group_owners", ["user_id"], name: "index_openstax_accounts_group_owners_on_user_id", using: :btree

  create_table "openstax_accounts_groups", force: :cascade do |t|
    t.integer  "openstax_uid",                               null: false
    t.boolean  "is_public",                  default: false, null: false
    t.string   "name"
    t.text     "cached_subtree_group_ids"
    t.text     "cached_supertree_group_ids"
    t.datetime "created_at",                                 null: false
    t.datetime "updated_at",                                 null: false
  end

  add_index "openstax_accounts_groups", ["openstax_uid"], name: "index_openstax_accounts_groups_on_openstax_uid", unique: true, using: :btree

  create_table "role_users", force: :cascade do |t|
    t.integer  "entity_user_id", null: false
    t.integer  "entity_role_id", null: false
    t.datetime "created_at",     null: false
    t.datetime "updated_at",     null: false
  end

  add_index "role_users", ["entity_user_id", "entity_role_id"], name: "role_users_user_role_uniq", unique: true, using: :btree

  create_table "sections", force: :cascade do |t|
    t.integer  "course_id",  null: false
    t.string   "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_index "sections", ["course_id"], name: "index_sections_on_course_id", using: :btree
  add_index "sections", ["name", "course_id"], name: "index_sections_on_name_and_course_id", unique: true, using: :btree

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

  add_index "students", ["course_id"], name: "index_students_on_course_id", using: :btree
  add_index "students", ["educator_custom_identifier"], name: "index_students_on_educator_custom_identifier", using: :btree
  add_index "students", ["level"], name: "index_students_on_level", using: :btree
  add_index "students", ["random_education_identifier"], name: "index_students_on_random_education_identifier", unique: true, using: :btree
  add_index "students", ["section_id"], name: "index_students_on_section_id", using: :btree
  add_index "students", ["student_custom_identifier"], name: "index_students_on_student_custom_identifier", using: :btree
  add_index "students", ["user_id", "course_id"], name: "index_students_on_user_id_and_course_id", unique: true, using: :btree
  add_index "students", ["user_id", "section_id"], name: "index_students_on_user_id_and_section_id", unique: true, using: :btree

  create_table "tasks_assistants", force: :cascade do |t|
    t.string   "name",            null: false
    t.string   "code_class_name", null: false
    t.datetime "created_at",      null: false
    t.datetime "updated_at",      null: false
  end

  add_index "tasks_assistants", ["code_class_name"], name: "index_tasks_assistants_on_code_class_name", unique: true, using: :btree
  add_index "tasks_assistants", ["name"], name: "index_tasks_assistants_on_name", unique: true, using: :btree

  create_table "tasks_course_assistants", force: :cascade do |t|
    t.integer  "entity_course_id",     null: false
    t.integer  "tasks_assistant_id",   null: false
    t.string   "tasks_task_plan_type", null: false
    t.text     "settings"
    t.text     "data"
    t.datetime "created_at",           null: false
    t.datetime "updated_at",           null: false
  end

  add_index "tasks_course_assistants", ["entity_course_id", "tasks_task_plan_type"], name: "index_tasks_course_assistants_on_course_id_and_task_plan_type", unique: true, using: :btree
  add_index "tasks_course_assistants", ["tasks_assistant_id", "entity_course_id"], name: "index_tasks_course_assistants_on_assistant_id_and_course_id", using: :btree

  create_table "tasks_task_plans", force: :cascade do |t|
    t.integer  "tasks_assistant_id", null: false
    t.integer  "owner_id",           null: false
    t.string   "owner_type",         null: false
    t.string   "title"
    t.string   "type",               null: false
    t.text     "settings",           null: false
    t.datetime "opens_at"
    t.datetime "due_at"
    t.datetime "published_at"
    t.datetime "created_at",         null: false
    t.datetime "updated_at",         null: false
  end

  add_index "tasks_task_plans", ["due_at", "opens_at"], name: "index_tasks_task_plans_on_due_at_and_opens_at", using: :btree
  add_index "tasks_task_plans", ["owner_id", "owner_type"], name: "index_tasks_task_plans_on_owner_id_and_owner_type", using: :btree
  add_index "tasks_task_plans", ["tasks_assistant_id"], name: "index_tasks_task_plans_on_tasks_assistant_id", using: :btree

  create_table "tasks_task_steps", force: :cascade do |t|
    t.integer  "tasks_task_id",             null: false
    t.integer  "tasked_id",                 null: false
    t.string   "tasked_type",               null: false
    t.integer  "number",                    null: false
    t.datetime "completed_at"
    t.integer  "page_id"
    t.integer  "group_type",    default: 0, null: false
    t.datetime "created_at",                null: false
    t.datetime "updated_at",                null: false
  end

  add_index "tasks_task_steps", ["tasked_id", "tasked_type"], name: "index_tasks_task_steps_on_tasked_id_and_tasked_type", unique: true, using: :btree
  add_index "tasks_task_steps", ["tasks_task_id", "number"], name: "index_tasks_task_steps_on_tasks_task_id_and_number", unique: true, using: :btree

  create_table "tasks_tasked_exercises", force: :cascade do |t|
    t.integer  "content_exercise_id"
    t.boolean  "can_be_recovered",    default: false, null: false
    t.string   "url",                                 null: false
    t.text     "content",                             null: false
    t.string   "title"
    t.text     "free_response"
    t.string   "answer_id"
    t.datetime "created_at",                          null: false
    t.datetime "updated_at",                          null: false
  end

  add_index "tasks_tasked_exercises", ["content_exercise_id"], name: "index_tasks_tasked_exercises_on_content_exercise_id", using: :btree

  create_table "tasks_tasked_interactives", force: :cascade do |t|
    t.string   "url",        null: false
    t.text     "content",    null: false
    t.string   "title"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "tasks_tasked_placeholders", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "tasks_tasked_readings", force: :cascade do |t|
    t.string   "url",        null: false
    t.text     "content",    null: false
    t.string   "title"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string   "path"
  end

  create_table "tasks_tasked_videos", force: :cascade do |t|
    t.string   "url",        null: false
    t.text     "content",    null: false
    t.string   "title"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "tasks_tasking_plans", force: :cascade do |t|
    t.integer  "target_id",          null: false
    t.string   "target_type",        null: false
    t.integer  "tasks_task_plan_id", null: false
    t.datetime "created_at",         null: false
    t.datetime "updated_at",         null: false
  end

  add_index "tasks_tasking_plans", ["target_id", "target_type", "tasks_task_plan_id"], name: "index_tasking_plans_on_t_id_and_t_type_and_t_p_id", unique: true, using: :btree
  add_index "tasks_tasking_plans", ["tasks_task_plan_id"], name: "index_tasks_tasking_plans_on_tasks_task_plan_id", using: :btree

  create_table "tasks_taskings", force: :cascade do |t|
    t.integer  "entity_role_id", null: false
    t.integer  "entity_task_id", null: false
    t.datetime "created_at",     null: false
    t.datetime "updated_at",     null: false
  end

  add_index "tasks_taskings", ["entity_role_id", "entity_task_id"], name: "[\"tasks_taskings_role_id_on_task_id_unique\"]", unique: true, using: :btree
  add_index "tasks_taskings", ["entity_task_id"], name: "index_tasks_taskings_on_entity_task_id", using: :btree

  create_table "tasks_tasks", force: :cascade do |t|
    t.integer  "tasks_task_plan_id"
    t.integer  "entity_task_id"
    t.string   "task_type",                             null: false
    t.string   "title",                                 null: false
    t.datetime "opens_at"
    t.datetime "due_at"
    t.text     "description"
    t.integer  "tasks_taskings_count",      default: 0, null: false
    t.text     "spaced_practice_algorithm",             null: false
    t.datetime "created_at",                            null: false
    t.datetime "updated_at",                            null: false
  end

  add_index "tasks_tasks", ["due_at", "opens_at"], name: "index_tasks_tasks_on_due_at_and_opens_at", using: :btree
  add_index "tasks_tasks", ["entity_task_id"], name: "index_tasks_tasks_on_entity_task_id", using: :btree
  add_index "tasks_tasks", ["task_type"], name: "index_tasks_tasks_on_task_type", using: :btree
  add_index "tasks_tasks", ["tasks_task_plan_id"], name: "index_tasks_tasks_on_tasks_task_plan_id", using: :btree

  create_table "user_profile_profiles", force: :cascade do |t|
    t.integer  "entity_user_id",      null: false
    t.integer  "account_id",          null: false
    t.string   "exchange_identifier", null: false
    t.datetime "deleted_at"
    t.datetime "created_at",          null: false
    t.datetime "updated_at",          null: false
  end

  add_index "user_profile_profiles", ["account_id"], name: "index_user_profile_profiles_on_account_id", unique: true, using: :btree
  add_index "user_profile_profiles", ["deleted_at"], name: "index_user_profile_profiles_on_deleted_at", using: :btree
  add_index "user_profile_profiles", ["exchange_identifier"], name: "index_user_profile_profiles_on_exchange_identifier", unique: true, using: :btree

  add_foreign_key "administrators", "user_profile_profiles", column: "profile_id", on_update: :cascade, on_delete: :cascade
  add_foreign_key "content_book_parts", "content_book_parts", column: "parent_book_part_id", on_update: :cascade, on_delete: :cascade
  add_foreign_key "content_book_parts", "entity_books", on_update: :cascade, on_delete: :cascade
  add_foreign_key "content_exercise_tags", "content_exercises", on_update: :cascade, on_delete: :cascade
  add_foreign_key "content_exercise_tags", "content_tags", on_update: :cascade, on_delete: :cascade
  add_foreign_key "content_page_tags", "content_pages", on_update: :cascade, on_delete: :cascade
  add_foreign_key "content_page_tags", "content_tags", on_update: :cascade, on_delete: :cascade
  add_foreign_key "content_pages", "content_book_parts", on_update: :cascade, on_delete: :cascade
  add_foreign_key "course_content_course_books", "entity_books"
  add_foreign_key "course_content_course_books", "entity_courses"
  add_foreign_key "course_membership_students", "entity_courses"
  add_foreign_key "course_membership_students", "entity_roles"
  add_foreign_key "course_membership_teachers", "entity_courses"
  add_foreign_key "course_membership_teachers", "entity_roles"
  add_foreign_key "course_profile_profiles", "entity_courses"
  add_foreign_key "educators", "courses", on_update: :cascade, on_delete: :cascade
  add_foreign_key "educators", "user_profile_profiles", column: "user_id", on_update: :cascade, on_delete: :cascade
  add_foreign_key "role_users", "entity_roles"
  add_foreign_key "role_users", "entity_users"
  add_foreign_key "sections", "courses", on_update: :cascade, on_delete: :cascade
  add_foreign_key "students", "courses", on_update: :cascade, on_delete: :cascade
  add_foreign_key "students", "sections", on_update: :cascade, on_delete: :cascade
  add_foreign_key "students", "user_profile_profiles", column: "user_id", on_update: :cascade, on_delete: :cascade
  add_foreign_key "tasks_course_assistants", "entity_courses", on_update: :cascade, on_delete: :cascade
  add_foreign_key "tasks_course_assistants", "tasks_assistants", on_update: :cascade, on_delete: :cascade
  add_foreign_key "tasks_task_plans", "tasks_assistants", on_update: :cascade, on_delete: :cascade
  add_foreign_key "tasks_task_steps", "tasks_tasks", on_update: :cascade, on_delete: :cascade
  add_foreign_key "tasks_tasking_plans", "tasks_task_plans", on_update: :cascade, on_delete: :cascade
  add_foreign_key "tasks_taskings", "entity_roles"
  add_foreign_key "tasks_taskings", "entity_tasks"
  add_foreign_key "tasks_tasks", "entity_tasks", on_update: :cascade, on_delete: :cascade
  add_foreign_key "tasks_tasks", "tasks_task_plans", on_update: :cascade, on_delete: :cascade
end
