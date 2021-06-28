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

ActiveRecord::Schema.define(version: 2021_06_22_152149) do

  create_sequence "active_storage_attachments_id_seq"
  create_sequence "active_storage_blobs_id_seq"
  create_sequence "catalog_offerings_id_seq"
  create_sequence "content_books_id_seq"
  create_sequence "content_ecosystems_id_seq"
  create_sequence "content_exercise_tags_id_seq"
  create_sequence "content_exercises_id_seq"
  create_sequence "content_lo_teks_tags_id_seq"
  create_sequence "content_maps_id_seq"
  create_sequence "content_notes_id_seq"
  create_sequence "content_page_tags_id_seq"
  create_sequence "content_pages_id_seq"
  create_sequence "content_tags_id_seq"
  create_sequence "course_content_course_ecosystems_id_seq"
  create_sequence "course_content_excluded_exercises_id_seq"
  create_sequence "course_membership_enrollment_changes_id_seq"
  create_sequence "course_membership_enrollments_id_seq"
  create_sequence "course_membership_periods_id_seq"
  create_sequence "course_membership_students_id_seq"
  create_sequence "course_membership_teacher_students_id_seq"
  create_sequence "course_membership_teachers_id_seq"
  create_sequence "course_profile_caches_id_seq"
  create_sequence "course_profile_courses_id_seq"
  create_sequence "delayed_jobs_id_seq"
  create_sequence "delayed_workers_id_seq"
  create_sequence "entity_roles_id_seq"
  create_sequence "environments_id_seq"
  create_sequence "fine_print_contracts_id_seq"
  create_sequence "fine_print_signatures_id_seq"
  create_sequence "legal_targeted_contracts_id_seq"
  create_sequence "lms_apps_id_seq"
  create_sequence "lms_contexts_id_seq"
  create_sequence "lms_course_score_callbacks_id_seq"
  create_sequence "lms_nonces_id_seq"
  create_sequence "lms_tool_consumers_id_seq"
  create_sequence "lms_trusted_launch_data_id_seq"
  create_sequence "lms_users_id_seq"
  create_sequence "oauth_access_grants_id_seq"
  create_sequence "oauth_access_tokens_id_seq"
  create_sequence "oauth_applications_id_seq"
  create_sequence "openstax_accounts_accounts_id_seq"
  create_sequence "openstax_salesforce_users_id_seq"
  create_sequence "ratings_exercise_group_book_parts_id_seq"
  create_sequence "ratings_period_book_parts_id_seq"
  create_sequence "ratings_role_book_parts_id_seq"
  create_sequence "research_cohort_members_id_seq"
  create_sequence "research_cohorts_id_seq"
  create_sequence "research_manipulations_id_seq"
  create_sequence "research_studies_id_seq"
  create_sequence "research_study_brains_id_seq"
  create_sequence "research_study_courses_id_seq"
  create_sequence "research_survey_plans_id_seq"
  create_sequence "research_surveys_id_seq"
  create_sequence "school_district_districts_id_seq"
  create_sequence "school_district_schools_id_seq"
  create_sequence "settings_id_seq"
  create_sequence "short_code_short_codes_id_seq"
  create_sequence "tasks_assistants_id_seq"
  create_sequence "tasks_concept_coach_tasks_id_seq"
  create_sequence "tasks_course_assistants_id_seq"
  create_sequence "tasks_dropped_questions_id_seq"
  create_sequence "tasks_extensions_id_seq"
  create_sequence "tasks_grading_templates_id_seq"
  create_sequence "tasks_performance_report_exports_id_seq"
  create_sequence "tasks_practice_questions_id_seq"
  create_sequence "tasks_task_plans_id_seq"
  create_sequence "tasks_task_steps_id_seq"
  create_sequence "tasks_tasked_exercises_id_seq"
  create_sequence "tasks_tasked_external_urls_id_seq"
  create_sequence "tasks_tasked_interactives_id_seq"
  create_sequence "tasks_tasked_placeholders_id_seq"
  create_sequence "tasks_tasked_readings_id_seq"
  create_sequence "tasks_tasked_videos_id_seq"
  create_sequence "tasks_tasking_plans_id_seq"
  create_sequence "tasks_taskings_id_seq"
  create_sequence "tasks_tasks_id_seq"
  create_sequence "teacher_exercise_number", start: 1000000
  create_sequence "user_administrators_id_seq"
  create_sequence "user_content_analysts_id_seq"
  create_sequence "user_customer_services_id_seq"
  create_sequence "user_profiles_id_seq"
  create_sequence "user_researchers_id_seq"
  create_sequence "user_suggestions_id_seq"
  create_sequence "user_tour_views_id_seq"
  create_sequence "user_tours_id_seq"

  # These are extensions that must be enabled in order to support this database
  enable_extension "citext"
  enable_extension "pgcrypto"
  enable_extension "plpgsql"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.bigint "byte_size", null: false
    t.string "checksum", null: false
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "catalog_offerings", id: :serial, force: :cascade do |t|
    t.string "salesforce_book_name", null: false
    t.integer "content_ecosystem_id"
    t.boolean "is_tutor", default: false, null: false
    t.boolean "is_concept_coach", default: false, null: false
    t.string "description", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "default_course_name"
    t.string "appearance_code"
    t.boolean "is_available", null: false
    t.string "title", null: false
    t.integer "number", null: false
    t.boolean "does_cost", default: false, null: false
    t.boolean "is_preview_available", null: false
    t.text "preview_message"
    t.datetime "deleted_at"
    t.string "subject"
    t.string "os_book_id"
    t.index ["content_ecosystem_id"], name: "index_catalog_offerings_on_content_ecosystem_id"
    t.index ["number"], name: "index_catalog_offerings_on_number", unique: true
    t.index ["salesforce_book_name"], name: "index_catalog_offerings_on_salesforce_book_name"
    t.index ["title"], name: "index_catalog_offerings_on_title"
  end

  create_table "content_books", id: :serial, force: :cascade do |t|
    t.string "url", null: false
    t.text "content"
    t.integer "content_ecosystem_id", null: false
    t.string "title", null: false
    t.string "uuid", null: false
    t.string "version", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "short_id"
    t.text "reading_processing_instructions", default: "[]", null: false
    t.uuid "tutor_uuid", default: -> { "gen_random_uuid()" }, null: false
    t.datetime "baked_at"
    t.boolean "is_collated", default: false
    t.jsonb "tree", null: false
    t.string "archive_version"
    t.index ["content_ecosystem_id"], name: "index_content_books_on_content_ecosystem_id"
    t.index ["title"], name: "index_content_books_on_title"
    t.index ["tutor_uuid"], name: "index_content_books_on_tutor_uuid", unique: true
    t.index ["url"], name: "index_content_books_on_url"
  end

  create_table "content_ecosystems", id: :serial, force: :cascade do |t|
    t.string "title", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "comments"
    t.uuid "tutor_uuid", default: -> { "gen_random_uuid()" }, null: false
    t.datetime "deleted_at"
    t.index ["created_at"], name: "index_content_ecosystems_on_created_at"
    t.index ["title"], name: "index_content_ecosystems_on_title"
    t.index ["tutor_uuid"], name: "index_content_ecosystems_on_tutor_uuid", unique: true
  end

  create_table "content_exercise_tags", id: :serial, force: :cascade do |t|
    t.integer "content_exercise_id", null: false
    t.integer "content_tag_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["content_exercise_id", "content_tag_id"], name: "index_content_exercise_tags_on_c_e_id_and_c_t_id", unique: true
    t.index ["content_tag_id"], name: "index_content_exercise_tags_on_content_tag_id"
  end

  create_table "content_exercises", id: :serial, force: :cascade do |t|
    t.string "url"
    t.text "content"
    t.integer "content_page_id", null: false
    t.bigint "number", null: false
    t.integer "version", null: false
    t.string "title"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "preview"
    t.text "context"
    t.boolean "has_interactive", default: false, null: false
    t.boolean "has_video", default: false, null: false
    t.uuid "uuid", null: false
    t.uuid "group_uuid", null: false
    t.string "nickname"
    t.jsonb "question_answer_ids", null: false
    t.integer "number_of_questions", null: false
    t.integer "user_profile_id", default: 0, null: false
    t.boolean "is_copyable", default: true, null: false
    t.boolean "anonymize_author", default: false, null: false
    t.bigint "derived_from_id"
    t.integer "coauthor_profile_ids", default: [], array: true
    t.datetime "deleted_at"
    t.index ["content_page_id"], name: "index_content_exercises_on_content_page_id"
    t.index ["derived_from_id"], name: "index_content_exercises_on_derived_from_id"
    t.index ["group_uuid", "version"], name: "index_content_exercises_on_group_uuid_and_version"
    t.index ["number", "version"], name: "index_content_exercises_on_number_and_version"
    t.index ["title"], name: "index_content_exercises_on_title"
    t.index ["url"], name: "index_content_exercises_on_url"
    t.index ["user_profile_id"], name: "index_content_exercises_on_user_profile_id"
    t.index ["uuid"], name: "index_content_exercises_on_uuid"
  end

  create_table "content_lo_teks_tags", id: :serial, force: :cascade do |t|
    t.integer "lo_id", null: false
    t.integer "teks_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["lo_id", "teks_id"], name: "content_lo_teks_tag_lo_teks_uniq", unique: true
  end

  create_table "content_maps", id: :serial, force: :cascade do |t|
    t.integer "content_from_ecosystem_id", null: false
    t.integer "content_to_ecosystem_id", null: false
    t.boolean "is_valid", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "exercise_id_to_page_id_map", default: "{}", null: false
    t.text "page_id_to_page_id_map", default: "{}", null: false
    t.text "page_id_to_pool_type_exercise_ids_map", default: "{}", null: false
    t.text "validity_error_messages", default: "[]", null: false
    t.index ["content_from_ecosystem_id", "content_to_ecosystem_id"], name: "index_content_maps_on_from_ecosystem_id_and_to_ecosystem_id", unique: true
    t.index ["content_to_ecosystem_id"], name: "index_content_maps_on_content_to_ecosystem_id"
  end

  create_table "content_notes", id: :serial, force: :cascade do |t|
    t.integer "content_page_id", null: false
    t.integer "entity_role_id", null: false
    t.text "anchor", null: false
    t.text "annotation"
    t.jsonb "contents", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["content_page_id"], name: "index_content_notes_on_content_page_id"
    t.index ["entity_role_id"], name: "index_content_notes_on_entity_role_id"
  end

  create_table "content_page_tags", id: :serial, force: :cascade do |t|
    t.integer "content_page_id", null: false
    t.integer "content_tag_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["content_page_id", "content_tag_id"], name: "index_content_page_tags_on_content_page_id_and_content_tag_id", unique: true
    t.index ["content_tag_id"], name: "index_content_page_tags_on_content_tag_id"
  end

  create_table "content_pages", id: :serial, force: :cascade do |t|
    t.string "url", null: false
    t.text "content"
    t.string "title", null: false
    t.string "uuid", null: false
    t.string "version"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "short_id"
    t.text "fragments", default: "[]", null: false
    t.text "snap_labs", default: "[]", null: false
    t.uuid "tutor_uuid", default: -> { "gen_random_uuid()" }, null: false
    t.text "book_location", default: "[]", null: false
    t.bigint "content_book_id", null: false
    t.integer "all_exercise_ids", default: [], null: false, array: true
    t.integer "reading_dynamic_exercise_ids", default: [], null: false, array: true
    t.integer "reading_context_exercise_ids", default: [], null: false, array: true
    t.integer "homework_core_exercise_ids", default: [], null: false, array: true
    t.integer "homework_dynamic_exercise_ids", default: [], null: false, array: true
    t.integer "practice_widget_exercise_ids", default: [], null: false, array: true
    t.integer "book_indices", null: false, array: true
    t.uuid "parent_book_part_uuid", null: false
    t.index ["content_book_id"], name: "index_content_pages_on_content_book_id"
    t.index ["parent_book_part_uuid"], name: "index_content_pages_on_parent_book_part_uuid"
    t.index ["title"], name: "index_content_pages_on_title"
    t.index ["tutor_uuid"], name: "index_content_pages_on_tutor_uuid", unique: true
    t.index ["url"], name: "index_content_pages_on_url"
    t.index ["uuid"], name: "index_content_pages_on_uuid"
  end

  create_table "content_tags", id: :serial, force: :cascade do |t|
    t.integer "content_ecosystem_id", null: false
    t.string "value", null: false
    t.integer "tag_type", default: 0, null: false
    t.string "name"
    t.text "description"
    t.string "data"
    t.boolean "visible"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["content_ecosystem_id"], name: "index_content_tags_on_content_ecosystem_id"
    t.index ["tag_type"], name: "index_content_tags_on_tag_type"
    t.index ["value", "content_ecosystem_id"], name: "index_content_tags_on_value_and_content_ecosystem_id", unique: true
  end

  create_table "course_content_course_ecosystems", id: :serial, force: :cascade do |t|
    t.integer "course_profile_course_id", null: false
    t.integer "content_ecosystem_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["content_ecosystem_id", "course_profile_course_id"], name: "course_ecosystems_on_ecosystem_id_course_id"
    t.index ["course_profile_course_id", "created_at"], name: "course_ecosystems_on_course_id_created_at"
  end

  create_table "course_content_excluded_exercises", id: :serial, force: :cascade do |t|
    t.integer "course_profile_course_id", null: false
    t.integer "exercise_number", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["course_profile_course_id"], name: "index_c_c_excluded_exercises_on_c_p_course_id"
    t.index ["exercise_number", "course_profile_course_id"], name: "index_excluded_exercises_on_number_and_course_id", unique: true
  end

  create_table "course_membership_enrollment_changes", id: :serial, force: :cascade do |t|
    t.integer "user_profile_id", null: false
    t.integer "course_membership_enrollment_id"
    t.integer "course_membership_period_id", null: false
    t.integer "status", default: 0, null: false
    t.boolean "requires_enrollee_approval", default: true, null: false
    t.datetime "enrollee_approved_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "course_membership_conflicting_enrollment_id"
    t.index ["course_membership_conflicting_enrollment_id"], name: "index_c_m_enrollment_changes_on_c_m_conflicting_enrollment_id"
    t.index ["course_membership_enrollment_id"], name: "index_course_membership_enrollments_on_enrollment_id"
    t.index ["course_membership_period_id"], name: "index_course_membership_enrollment_changes_on_period_id"
    t.index ["user_profile_id"], name: "index_course_membership_enrollment_changes_on_user_profile_id"
  end

  create_table "course_membership_enrollments", id: :serial, force: :cascade do |t|
    t.integer "course_membership_period_id", null: false
    t.integer "course_membership_student_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "sequence_number", null: false
    t.index ["course_membership_period_id", "course_membership_student_id"], name: "course_membership_enrollments_period_student"
    t.index ["course_membership_student_id", "sequence_number"], name: "index_enrollments_on_student_id_and_sequence_number", unique: true
  end

  create_table "course_membership_periods", id: :serial, force: :cascade do |t|
    t.integer "course_profile_course_id", null: false
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "enrollment_code", null: false
    t.datetime "archived_at"
    t.uuid "uuid", default: -> { "gen_random_uuid()" }, null: false
    t.index ["archived_at"], name: "index_course_membership_periods_on_archived_at"
    t.index ["course_profile_course_id"], name: "index_course_membership_periods_on_course_profile_course_id"
    t.index ["enrollment_code"], name: "index_course_membership_periods_on_enrollment_code", unique: true
    t.index ["name", "course_profile_course_id"], name: "index_c_m_periods_on_name_and_c_p_course_id"
    t.index ["uuid"], name: "index_course_membership_periods_on_uuid", unique: true
  end

  create_table "course_membership_students", id: :serial, force: :cascade do |t|
    t.integer "course_profile_course_id", null: false
    t.integer "entity_role_id", null: false
    t.datetime "dropped_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "student_identifier"
    t.uuid "uuid", default: -> { "gen_random_uuid()" }, null: false
    t.datetime "first_paid_at"
    t.boolean "is_paid", default: false, null: false
    t.boolean "is_comped", default: false, null: false
    t.datetime "payment_due_at", null: false
    t.boolean "is_refund_pending", default: false, null: false
    t.jsonb "refund_survey_response", default: {}
    t.integer "course_membership_period_id", null: false
    t.index ["course_membership_period_id"], name: "index_course_membership_students_on_course_membership_period_id"
    t.index ["course_profile_course_id", "student_identifier"], name: "index_course_membership_students_on_c_p_c_id_and_s_identifier"
    t.index ["dropped_at"], name: "index_course_membership_students_on_dropped_at"
    t.index ["entity_role_id"], name: "index_course_membership_students_on_entity_role_id", unique: true
    t.index ["uuid"], name: "index_course_membership_students_on_uuid", unique: true
  end

  create_table "course_membership_teacher_students", id: :serial, force: :cascade do |t|
    t.integer "course_profile_course_id", null: false
    t.integer "course_membership_period_id", null: false
    t.integer "entity_role_id", null: false
    t.uuid "uuid", default: -> { "gen_random_uuid()" }, null: false
    t.datetime "deleted_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["course_membership_period_id"], name: "index_teacher_students_on_period_id"
    t.index ["course_profile_course_id"], name: "index_teacher_students_on_course_id"
    t.index ["entity_role_id"], name: "index_course_membership_teacher_students_on_entity_role_id", unique: true
    t.index ["uuid"], name: "index_course_membership_teacher_students_on_uuid", unique: true
  end

  create_table "course_membership_teachers", id: :serial, force: :cascade do |t|
    t.integer "course_profile_course_id", null: false
    t.integer "entity_role_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "deleted_at"
    t.index ["course_profile_course_id"], name: "index_course_membership_teachers_on_course_profile_course_id"
    t.index ["entity_role_id"], name: "index_course_membership_teachers_on_entity_role_id", unique: true
  end

  create_table "course_profile_caches", force: :cascade do |t|
    t.bigint "course_profile_course_id", null: false
    t.jsonb "teacher_performance_report", null: false, array: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["course_profile_course_id"], name: "index_course_profile_caches_on_course_profile_course_id"
  end

  create_table "course_profile_courses", id: :serial, force: :cascade do |t|
    t.integer "school_district_school_id"
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "is_concept_coach", null: false
    t.string "teach_token", null: false
    t.integer "catalog_offering_id"
    t.string "appearance_code"
    t.boolean "is_college"
    t.datetime "starts_at", null: false
    t.datetime "ends_at", null: false
    t.integer "term", null: false
    t.integer "year", null: false
    t.integer "cloned_from_id"
    t.boolean "is_preview", null: false
    t.boolean "is_excluded_from_salesforce", default: false, null: false
    t.uuid "uuid", default: -> { "gen_random_uuid()" }, null: false
    t.boolean "is_test", default: false, null: false
    t.boolean "does_cost", default: false, null: false
    t.integer "estimated_student_count"
    t.datetime "preview_claimed_at"
    t.boolean "is_preview_ready", default: false, null: false
    t.datetime "deleted_at"
    t.boolean "is_lms_enabled"
    t.boolean "is_lms_enabling_allowed", default: false, null: false
    t.boolean "is_access_switchable", default: true, null: false
    t.string "last_lms_scores_push_job_id"
    t.string "creator_campaign_member_id"
    t.string "latest_adoption_decision"
    t.float "homework_weight", default: 0.5, null: false
    t.float "reading_weight", default: 0.5, null: false
    t.string "timezone", null: false
    t.boolean "past_due_unattempted_ungraded_wrq_are_zero", default: true, null: false
    t.bigint "environment_id", null: false
    t.string "code"
    t.index ["catalog_offering_id"], name: "index_course_profile_courses_on_catalog_offering_id"
    t.index ["cloned_from_id"], name: "index_course_profile_courses_on_cloned_from_id"
    t.index ["environment_id"], name: "index_course_profile_courses_on_environment_id"
    t.index ["is_lms_enabling_allowed"], name: "index_course_profile_courses_on_is_lms_enabling_allowed"
    t.index ["is_preview", "is_preview_ready", "preview_claimed_at", "catalog_offering_id"], name: "preview_pending_index"
    t.index ["name"], name: "index_course_profile_courses_on_name"
    t.index ["school_district_school_id"], name: "index_course_profile_courses_on_school_district_school_id"
    t.index ["teach_token"], name: "index_course_profile_courses_on_teach_token", unique: true
    t.index ["uuid"], name: "index_course_profile_courses_on_uuid", unique: true
    t.index ["year", "term"], name: "index_course_profile_courses_on_year_and_term"
  end

  create_table "delayed_jobs", id: :serial, force: :cascade do |t|
    t.integer "priority", default: 0, null: false
    t.integer "attempts", default: 0, null: false
    t.text "handler", null: false
    t.text "last_error"
    t.datetime "run_at"
    t.datetime "locked_at"
    t.datetime "failed_at"
    t.string "locked_by"
    t.string "queue"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["priority", "run_at"], name: "delayed_jobs_priority"
  end

  create_table "delayed_workers", force: :cascade do |t|
    t.string "name"
    t.string "version"
    t.datetime "last_heartbeat_at"
    t.string "host_name"
    t.string "label"
  end

  create_table "entity_roles", id: :serial, force: :cascade do |t|
    t.integer "role_type", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "research_identifier", null: false
    t.integer "user_profile_id", null: false
    t.index ["research_identifier"], name: "index_entity_roles_on_research_identifier", unique: true
    t.index ["role_type"], name: "index_entity_roles_on_role_type"
    t.index ["user_profile_id"], name: "index_entity_roles_on_user_profile_id"
  end

  create_table "environments", force: :cascade do |t|
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_environments_on_name", unique: true
  end

  create_table "fine_print_contracts", id: :serial, force: :cascade do |t|
    t.string "name", null: false
    t.integer "version"
    t.string "title", null: false
    t.text "content", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name", "version"], name: "index_fine_print_contracts_on_name_and_version", unique: true
  end

  create_table "fine_print_signatures", id: :serial, force: :cascade do |t|
    t.integer "contract_id", null: false
    t.string "user_type", null: false
    t.integer "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "is_implicit", default: false, null: false
    t.index ["contract_id"], name: "index_fine_print_signatures_on_contract_id"
    t.index ["user_id", "user_type", "contract_id"], name: "index_fine_print_signatures_on_u_id_and_u_type_and_c_id", unique: true
  end

  create_table "legal_targeted_contracts", id: :serial, force: :cascade do |t|
    t.string "target_gid", null: false
    t.string "target_name", null: false
    t.string "contract_name", null: false
    t.boolean "is_proxy_signed", default: false
    t.boolean "is_end_user_visible", default: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "masked_contract_names", default: "[]", null: false
    t.index ["target_gid"], name: "legal_targeted_contracts_target"
  end

  create_table "lms_apps", id: :serial, force: :cascade do |t|
    t.string "owner_type", null: false
    t.integer "owner_id", null: false
    t.string "key", null: false
    t.string "secret", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["key"], name: "index_lms_apps_on_key", unique: true
    t.index ["owner_type", "owner_id"], name: "index_lms_apps_on_owner_type_and_owner_id", unique: true
  end

  create_table "lms_contexts", id: :serial, force: :cascade do |t|
    t.string "lti_id", null: false
    t.integer "lms_tool_consumer_id", null: false
    t.integer "course_profile_course_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "app_type", null: false
    t.index ["course_profile_course_id"], name: "index_lms_contexts_on_course_profile_course_id"
    t.index ["lms_tool_consumer_id"], name: "index_lms_contexts_on_lms_tool_consumer_id"
    t.index ["lti_id", "lms_tool_consumer_id", "course_profile_course_id"], name: "lms_contexts_lti_id_tool_consumer_id_course_id", unique: true
    t.index ["lti_id"], name: "index_lms_contexts_on_lti_id"
  end

  create_table "lms_course_score_callbacks", id: :serial, force: :cascade do |t|
    t.string "result_sourcedid", null: false
    t.string "outcome_url", null: false
    t.integer "user_profile_id", null: false
    t.integer "course_profile_course_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "resource_link_id", null: false
    t.index ["course_profile_course_id", "user_profile_id", "resource_link_id"], name: "course_score_callbacks_on_course_user_link", unique: true
    t.index ["result_sourcedid", "outcome_url"], name: "course_score_callback_result_outcome", unique: true
    t.index ["user_profile_id"], name: "course_score_callbacks_on_user"
  end

  create_table "lms_nonces", id: :serial, force: :cascade do |t|
    t.string "value", limit: 128, null: false
    t.datetime "created_at", null: false
    t.integer "lms_app_id"
    t.datetime "updated_at", null: false
    t.integer "app_type", default: 0, null: false
    t.index ["lms_app_id"], name: "index_lms_nonces_on_lms_app_id"
  end

  create_table "lms_tool_consumers", id: :serial, force: :cascade do |t|
    t.string "guid", null: false
    t.string "product_family_code"
    t.string "version"
    t.string "name"
    t.string "description"
    t.string "url"
    t.string "contact_email"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["guid"], name: "index_lms_tool_consumers_on_guid", unique: true
  end

  create_table "lms_trusted_launch_data", id: :serial, force: :cascade do |t|
    t.json "request_params"
    t.string "request_url"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.uuid "uuid", default: -> { "gen_random_uuid()" }, null: false
    t.index ["created_at"], name: "index_lms_trusted_launch_data_on_created_at"
    t.index ["uuid"], name: "index_lms_trusted_launch_data_on_uuid", unique: true
  end

  create_table "lms_users", id: :serial, force: :cascade do |t|
    t.string "lti_user_id", null: false
    t.integer "openstax_accounts_accounts_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["lti_user_id"], name: "index_lms_users_on_lti_user_id"
    t.index ["openstax_accounts_accounts_id"], name: "index_lms_users_on_openstax_accounts_accounts_id"
  end

  create_table "oauth_access_grants", id: :serial, force: :cascade do |t|
    t.integer "resource_owner_id", null: false
    t.integer "application_id", null: false
    t.string "token", null: false
    t.integer "expires_in", null: false
    t.text "redirect_uri", null: false
    t.datetime "created_at", null: false
    t.datetime "revoked_at"
    t.string "scopes"
    t.index ["token"], name: "index_oauth_access_grants_on_token", unique: true
  end

  create_table "oauth_access_tokens", id: :serial, force: :cascade do |t|
    t.integer "resource_owner_id"
    t.integer "application_id"
    t.string "token", null: false
    t.string "refresh_token"
    t.integer "expires_in"
    t.datetime "revoked_at"
    t.datetime "created_at", null: false
    t.string "scopes"
    t.string "previous_refresh_token", default: "", null: false
    t.index ["refresh_token"], name: "index_oauth_access_tokens_on_refresh_token", unique: true
    t.index ["resource_owner_id"], name: "index_oauth_access_tokens_on_resource_owner_id"
    t.index ["token"], name: "index_oauth_access_tokens_on_token", unique: true
  end

  create_table "oauth_applications", id: :serial, force: :cascade do |t|
    t.string "name", null: false
    t.string "uid", null: false
    t.string "secret", null: false
    t.text "redirect_uri", null: false
    t.string "scopes", default: "", null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "owner_id"
    t.string "owner_type"
    t.boolean "confidential", default: true, null: false
    t.index ["owner_id", "owner_type"], name: "index_oauth_applications_on_owner_id_and_owner_type"
    t.index ["uid"], name: "index_oauth_applications_on_uid", unique: true
  end

  create_table "openstax_accounts_accounts", id: :serial, force: :cascade do |t|
    t.integer "openstax_uid"
    t.string "username"
    t.string "access_token"
    t.string "first_name"
    t.string "last_name"
    t.string "full_name"
    t.string "title"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "faculty_status", default: 0, null: false
    t.string "salesforce_contact_id"
    t.uuid "uuid", default: -> { "gen_random_uuid()" }, null: false
    t.integer "role", default: 0, null: false
    t.citext "support_identifier"
    t.boolean "is_test"
    t.integer "school_type", default: 0, null: false
    t.boolean "is_kip"
    t.integer "school_location", default: 0, null: false
    t.boolean "grant_tutor_access"
    t.index ["access_token"], name: "index_openstax_accounts_accounts_on_access_token", unique: true
    t.index ["faculty_status"], name: "index_openstax_accounts_accounts_on_faculty_status"
    t.index ["first_name"], name: "index_openstax_accounts_accounts_on_first_name"
    t.index ["full_name"], name: "index_openstax_accounts_accounts_on_full_name"
    t.index ["last_name"], name: "index_openstax_accounts_accounts_on_last_name"
    t.index ["openstax_uid"], name: "index_openstax_accounts_accounts_on_openstax_uid"
    t.index ["role"], name: "index_openstax_accounts_accounts_on_role"
    t.index ["salesforce_contact_id"], name: "index_openstax_accounts_accounts_on_salesforce_contact_id"
    t.index ["school_type"], name: "index_openstax_accounts_accounts_on_school_type"
    t.index ["support_identifier"], name: "index_openstax_accounts_accounts_on_support_identifier", unique: true
    t.index ["username"], name: "index_openstax_accounts_accounts_on_username"
    t.index ["uuid"], name: "index_openstax_accounts_accounts_on_uuid", unique: true
  end

  create_table "openstax_salesforce_users", id: :serial, force: :cascade do |t|
    t.string "name"
    t.string "uid", null: false
    t.string "oauth_token", null: false
    t.string "refresh_token", null: false
    t.string "instance_url", null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "ratings_exercise_group_book_parts", force: :cascade do |t|
    t.uuid "exercise_group_uuid", null: false
    t.uuid "book_part_uuid", null: false
    t.boolean "is_page", null: false
    t.integer "tasked_exercise_ids", null: false, array: true
    t.float "glicko_mu", null: false
    t.float "glicko_phi", null: false
    t.float "glicko_sigma", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["book_part_uuid"], name: "index_ratings_exercise_group_book_parts_on_book_part_uuid"
    t.index ["exercise_group_uuid", "book_part_uuid"], name: "index_ex_group_book_parts_on_ex_group_uuid_and_book_part_uuid", unique: true
  end

  create_table "ratings_period_book_parts", force: :cascade do |t|
    t.bigint "course_membership_period_id", null: false
    t.uuid "book_part_uuid", null: false
    t.boolean "is_page", null: false
    t.integer "num_students", null: false
    t.jsonb "clue", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "tasked_exercise_ids", null: false, array: true
    t.float "glicko_mu", null: false
    t.float "glicko_phi", null: false
    t.float "glicko_sigma", null: false
    t.index ["book_part_uuid"], name: "index_ratings_period_book_parts_on_book_part_uuid"
    t.index ["course_membership_period_id", "book_part_uuid"], name: "index_period_book_parts_on_period_id_and_book_part_uuid", unique: true
  end

  create_table "ratings_role_book_parts", force: :cascade do |t|
    t.bigint "entity_role_id", null: false
    t.uuid "book_part_uuid", null: false
    t.boolean "is_page", null: false
    t.jsonb "clue", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "tasked_exercise_ids", null: false, array: true
    t.float "glicko_mu", null: false
    t.float "glicko_phi", null: false
    t.float "glicko_sigma", null: false
    t.index ["book_part_uuid"], name: "index_ratings_role_book_parts_on_book_part_uuid"
    t.index ["entity_role_id", "book_part_uuid"], name: "index_role_book_parts_on_role_id_and_book_part_uuid", unique: true
  end

  create_table "research_cohort_members", id: :serial, force: :cascade do |t|
    t.integer "research_cohort_id", null: false
    t.integer "course_membership_student_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["course_membership_student_id"], name: "index_research_cohort_members_on_course_membership_student_id"
    t.index ["research_cohort_id", "course_membership_student_id"], name: "index_cohort_members_on_cohort_and_student", unique: true
    t.index ["research_cohort_id"], name: "index_research_cohort_members_on_research_cohort_id"
  end

  create_table "research_cohorts", id: :serial, force: :cascade do |t|
    t.integer "research_study_id", null: false
    t.string "name", null: false
    t.integer "cohort_members_count", default: 0, null: false
    t.boolean "is_accepting_members", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["research_study_id"], name: "index_research_cohorts_on_research_study_id"
  end

  create_table "research_manipulations", id: :serial, force: :cascade do |t|
    t.integer "research_study_id", null: false
    t.integer "research_cohort_id"
    t.integer "research_study_brain_id"
    t.string "target_type"
    t.integer "target_id"
    t.jsonb "context", default: {}, null: false
    t.datetime "created_at"
    t.index ["research_cohort_id"], name: "index_research_manipulations_on_research_cohort_id"
    t.index ["research_study_brain_id"], name: "index_research_manipulations_on_research_study_brain_id"
    t.index ["research_study_id"], name: "index_research_manipulations_on_research_study_id"
  end

  create_table "research_studies", id: :serial, force: :cascade do |t|
    t.string "name", null: false
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "activate_at"
    t.datetime "deactivate_at"
    t.datetime "last_activated_at"
    t.datetime "last_deactivated_at"
    t.index ["last_activated_at"], name: "index_research_studies_on_last_activated_at"
    t.index ["last_deactivated_at"], name: "index_research_studies_on_last_deactivated_at"
  end

  create_table "research_study_brains", id: :serial, force: :cascade do |t|
    t.integer "research_study_id", null: false
    t.text "name", null: false
    t.text "type", null: false
    t.text "code", null: false
    t.index ["research_study_id"], name: "index_research_study_brains_on_research_study_id"
  end

  create_table "research_study_courses", id: :serial, force: :cascade do |t|
    t.integer "research_study_id", null: false
    t.integer "course_profile_course_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["course_profile_course_id", "research_study_id"], name: "research_study_courses_on_course_and_study", unique: true
    t.index ["course_profile_course_id"], name: "index_research_study_courses_on_course_profile_course_id"
    t.index ["research_study_id"], name: "index_research_study_courses_on_research_study_id"
  end

  create_table "research_survey_plans", id: :serial, force: :cascade do |t|
    t.integer "research_study_id", null: false
    t.string "title_for_researchers", null: false
    t.string "title_for_students", null: false
    t.text "description"
    t.text "survey_js_model"
    t.datetime "published_at"
    t.datetime "hidden_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["hidden_at"], name: "index_research_survey_plans_on_hidden_at"
    t.index ["published_at"], name: "index_research_survey_plans_on_published_at"
    t.index ["research_study_id"], name: "index_research_survey_plans_on_research_study_id"
  end

  create_table "research_surveys", id: :serial, force: :cascade do |t|
    t.integer "research_survey_plan_id", null: false
    t.integer "course_membership_student_id", null: false
    t.jsonb "survey_js_response"
    t.datetime "completed_at"
    t.datetime "hidden_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "deleted_at"
    t.index ["completed_at"], name: "index_research_surveys_on_completed_at"
    t.index ["course_membership_student_id", "research_survey_plan_id"], name: "research_surveys_on_student_and_plan", unique: true
    t.index ["course_membership_student_id"], name: "research_surveys_on_student"
    t.index ["deleted_at"], name: "index_research_surveys_on_deleted_at"
    t.index ["hidden_at"], name: "index_research_surveys_on_hidden_at"
    t.index ["research_survey_plan_id"], name: "index_research_surveys_on_research_survey_plan_id"
  end

  create_table "school_district_districts", id: :serial, force: :cascade do |t|
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_school_district_districts_on_name", unique: true
  end

  create_table "school_district_schools", id: :serial, force: :cascade do |t|
    t.string "name", null: false
    t.integer "school_district_district_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name", "school_district_district_id"], name: "index_schools_on_name_and_district_id", unique: true
    t.index ["name"], name: "index_school_district_schools_on_name", unique: true, where: "(school_district_district_id IS NULL)"
    t.index ["school_district_district_id"], name: "index_school_district_schools_on_school_district_district_id"
  end

  create_table "settings", id: :serial, force: :cascade do |t|
    t.string "var", null: false
    t.text "value"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["var"], name: "index_settings_on_var", unique: true
  end

  create_table "short_code_short_codes", id: :serial, force: :cascade do |t|
    t.string "code", null: false
    t.text "uri", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["code"], name: "index_short_code_short_codes_on_code", unique: true
  end

  create_table "tasks_assistants", id: :serial, force: :cascade do |t|
    t.string "name", null: false
    t.string "code_class_name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["code_class_name"], name: "index_tasks_assistants_on_code_class_name", unique: true
    t.index ["name"], name: "index_tasks_assistants_on_name", unique: true
  end

  create_table "tasks_concept_coach_tasks", id: :serial, force: :cascade do |t|
    t.integer "content_page_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "entity_role_id", null: false
    t.integer "tasks_task_id", null: false
    t.index ["content_page_id"], name: "index_tasks_concept_coach_tasks_on_content_page_id"
    t.index ["entity_role_id", "content_page_id"], name: "index_tasks_concept_coach_tasks_on_e_r_id_and_c_p_id", unique: true
    t.index ["tasks_task_id"], name: "index_tasks_concept_coach_tasks_on_tasks_task_id", unique: true
  end

  create_table "tasks_course_assistants", id: :serial, force: :cascade do |t|
    t.integer "course_profile_course_id", null: false
    t.integer "tasks_assistant_id", null: false
    t.string "tasks_task_plan_type", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "settings", default: "{}", null: false
    t.text "data", default: "{}", null: false
    t.index ["course_profile_course_id", "tasks_task_plan_type"], name: "index_tasks_course_assistants_on_course_id_and_task_plan_type", unique: true
    t.index ["tasks_assistant_id", "course_profile_course_id"], name: "index_tasks_course_assistants_on_assistant_id_and_course_id"
  end

  create_table "tasks_dropped_questions", force: :cascade do |t|
    t.bigint "tasks_task_plan_id", null: false
    t.string "question_id", null: false
    t.integer "drop_method", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["tasks_task_plan_id", "question_id"], name: "index_dropped_questions_on_task_plan_and_question_id", unique: true
  end

  create_table "tasks_extensions", force: :cascade do |t|
    t.bigint "tasks_task_plan_id", null: false
    t.bigint "entity_role_id", null: false
    t.datetime "due_at_ntz", null: false
    t.datetime "closes_at_ntz", null: false
    t.index ["entity_role_id"], name: "index_tasks_extensions_on_entity_role_id"
    t.index ["tasks_task_plan_id", "entity_role_id"], name: "index_tasks_extensions_on_tasks_task_plan_id_and_entity_role_id", unique: true
  end

  create_table "tasks_grading_templates", force: :cascade do |t|
    t.bigint "course_profile_course_id", null: false
    t.integer "task_plan_type", null: false
    t.string "name", null: false
    t.float "completion_weight", null: false
    t.float "correctness_weight", null: false
    t.integer "auto_grading_feedback_on", null: false
    t.integer "manual_grading_feedback_on", null: false
    t.float "late_work_penalty", null: false
    t.integer "late_work_penalty_applied", null: false
    t.string "default_open_time", null: false
    t.string "default_due_time", null: false
    t.integer "default_due_date_offset_days", null: false
    t.integer "default_close_date_offset_days", null: false
    t.datetime "deleted_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "cloned_from_id"
    t.index ["cloned_from_id"], name: "index_tasks_grading_templates_on_cloned_from_id"
    t.index ["course_profile_course_id", "name"], name: "index_tasks_grading_templates_on_course_and_name", unique: true
    t.index ["course_profile_course_id", "task_plan_type", "deleted_at"], name: "index_tasks_grading_templates_on_course_type_and_deleted"
  end

  create_table "tasks_performance_report_exports", id: :serial, force: :cascade do |t|
    t.integer "course_profile_course_id", null: false
    t.integer "entity_role_id", null: false
    t.string "export"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["course_profile_course_id"], name: "index_t_performance_report_exports_on_c_p_course_id"
    t.index ["entity_role_id", "course_profile_course_id"], name: "index_performance_report_exports_on_role_and_course"
  end

  create_table "tasks_practice_questions", force: :cascade do |t|
    t.bigint "tasks_tasked_exercise_id", null: false
    t.bigint "content_exercise_id", null: false
    t.bigint "entity_role_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["content_exercise_id"], name: "index_tasks_practice_questions_on_content_exercise_id"
    t.index ["entity_role_id", "content_exercise_id"], name: "index_question_on_role_and_exercise", unique: true
    t.index ["tasks_tasked_exercise_id"], name: "index_tasks_practice_questions_on_tasks_tasked_exercise_id"
  end

  create_table "tasks_task_plans", id: :serial, force: :cascade do |t|
    t.integer "tasks_assistant_id", null: false
    t.integer "course_profile_course_id", null: false
    t.string "type", null: false
    t.string "title", null: false
    t.text "description"
    t.text "settings", null: false
    t.datetime "publish_last_requested_at"
    t.datetime "first_published_at"
    t.string "publish_job_uuid"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "content_ecosystem_id", null: false
    t.datetime "withdrawn_at"
    t.datetime "last_published_at"
    t.integer "cloned_from_id"
    t.boolean "is_preview", default: false
    t.integer "tasks_grading_template_id"
    t.integer "ungraded_step_count", default: 0, null: false
    t.integer "wrq_count", default: 0, null: false
    t.integer "gradable_step_count", default: 0, null: false
    t.datetime "updated_by_instructor_at"
    t.index ["cloned_from_id"], name: "index_tasks_task_plans_on_cloned_from_id"
    t.index ["content_ecosystem_id"], name: "index_tasks_task_plans_on_content_ecosystem_id"
    t.index ["course_profile_course_id"], name: "index_tasks_task_plans_on_course_profile_course_id"
    t.index ["tasks_assistant_id"], name: "index_tasks_task_plans_on_tasks_assistant_id"
    t.index ["tasks_grading_template_id"], name: "index_tasks_task_plans_on_tasks_grading_template_id"
    t.index ["withdrawn_at"], name: "index_tasks_task_plans_on_withdrawn_at"
  end

  create_table "tasks_task_steps", id: :serial, force: :cascade do |t|
    t.integer "tasks_task_id", null: false
    t.integer "tasked_id", null: false
    t.string "tasked_type", null: false
    t.integer "number", null: false
    t.datetime "first_completed_at"
    t.datetime "last_completed_at"
    t.integer "group_type", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "related_exercise_ids", default: "[]", null: false
    t.text "labels", default: "[]", null: false
    t.text "spy", default: "{}", null: false
    t.integer "content_page_id"
    t.integer "fragment_index"
    t.boolean "is_core", null: false
    t.index ["content_page_id"], name: "index_tasks_task_steps_on_content_page_id"
    t.index ["first_completed_at"], name: "index_tasks_task_steps_on_first_completed_at"
    t.index ["last_completed_at"], name: "index_tasks_task_steps_on_last_completed_at"
    t.index ["tasked_id", "tasked_type"], name: "index_tasks_task_steps_on_tasked_id_and_tasked_type", unique: true
    t.index ["tasks_task_id", "number"], name: "index_tasks_task_steps_on_tasks_task_id_and_number", unique: true
  end

  create_table "tasks_tasked_exercises", id: :serial, force: :cascade do |t|
    t.integer "content_exercise_id", null: false
    t.string "url"
    t.string "title"
    t.text "free_response"
    t.string "answer_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "correct_answer_id"
    t.boolean "is_in_multipart", default: false, null: false
    t.string "question_id", null: false
    t.uuid "uuid", default: -> { "gen_random_uuid()" }, null: false
    t.integer "question_index", null: false
    t.jsonb "response_validation"
    t.text "content"
    t.text "context"
    t.string "answer_ids", null: false, array: true
    t.float "grader_points"
    t.text "grader_comments"
    t.datetime "last_graded_at"
    t.float "published_grader_points"
    t.text "published_comments"
    t.index "COALESCE(jsonb_array_length((response_validation -> 'attempts'::text)), 0)", name: "tasked_exercise_nudges_index"
    t.index ["content_exercise_id"], name: "index_tasks_tasked_exercises_on_content_exercise_id"
    t.index ["question_id"], name: "index_tasks_tasked_exercises_on_question_id"
    t.index ["updated_at"], name: "index_tasks_tasked_exercises_on_updated_at"
    t.index ["uuid"], name: "index_tasks_tasked_exercises_on_uuid", unique: true
  end

  create_table "tasks_tasked_external_urls", id: :serial, force: :cascade do |t|
    t.string "url", null: false
    t.string "title"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "tasks_tasked_interactives", id: :serial, force: :cascade do |t|
    t.string "url", null: false
    t.text "content", null: false
    t.string "title"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "tasks_tasked_placeholders", id: :serial, force: :cascade do |t|
    t.integer "placeholder_type", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "tasks_tasked_readings", id: :serial, force: :cascade do |t|
    t.string "url", null: false
    t.text "content"
    t.string "title"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "book_location", default: "[]", null: false
  end

  create_table "tasks_tasked_videos", id: :serial, force: :cascade do |t|
    t.string "url", null: false
    t.text "content", null: false
    t.string "title"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "tasks_tasking_plans", id: :serial, force: :cascade do |t|
    t.string "target_type", null: false
    t.integer "target_id", null: false
    t.integer "tasks_task_plan_id", null: false
    t.datetime "opens_at_ntz", null: false
    t.datetime "due_at_ntz", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "closes_at_ntz", null: false
    t.integer "gradable_step_count", default: 0, null: false
    t.integer "ungraded_step_count", default: 0, null: false
    t.index ["due_at_ntz", "opens_at_ntz"], name: "index_tasks_tasking_plans_on_due_at_ntz_and_opens_at_ntz"
    t.index ["opens_at_ntz"], name: "index_tasks_tasking_plans_on_opens_at_ntz"
    t.index ["target_id", "target_type", "tasks_task_plan_id"], name: "index_tasking_plans_on_t_id_and_t_type_and_t_p_id", unique: true
    t.index ["tasks_task_plan_id"], name: "index_tasks_tasking_plans_on_tasks_task_plan_id"
  end

  create_table "tasks_taskings", id: :serial, force: :cascade do |t|
    t.integer "entity_role_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "tasks_task_id", null: false
    t.index ["entity_role_id"], name: "index_tasks_taskings_on_entity_role_id"
    t.index ["tasks_task_id", "entity_role_id"], name: "index_tasks_taskings_on_tasks_task_id_and_entity_role_id", unique: true
  end

  create_table "tasks_tasks", id: :serial, force: :cascade do |t|
    t.integer "tasks_task_plan_id"
    t.integer "task_type", null: false
    t.string "title", null: false
    t.text "description"
    t.datetime "opens_at_ntz"
    t.datetime "due_at_ntz"
    t.datetime "last_worked_at"
    t.integer "steps_count", default: 0, null: false
    t.integer "completed_steps_count", default: 0, null: false
    t.integer "core_steps_count", default: 0, null: false
    t.integer "completed_core_steps_count", default: 0, null: false
    t.integer "exercise_steps_count", default: 0, null: false
    t.integer "completed_exercise_steps_count", default: 0, null: false
    t.integer "recovered_exercise_steps_count", default: 0, null: false
    t.integer "correct_exercise_steps_count", default: 0, null: false
    t.integer "placeholder_steps_count", default: 0, null: false
    t.integer "placeholder_exercise_steps_count", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "spy", default: "{}", null: false
    t.integer "correct_on_time_exercise_steps_count", default: 0, null: false
    t.integer "completed_on_time_exercise_steps_count", default: 0, null: false
    t.integer "completed_on_time_steps_count", default: 0, null: false
    t.datetime "hidden_at"
    t.uuid "uuid", default: -> { "gen_random_uuid()" }, null: false
    t.integer "content_ecosystem_id", null: false
    t.boolean "spes_are_assigned", default: false, null: false
    t.boolean "pes_are_assigned", default: false, null: false
    t.integer "core_placeholder_exercise_steps_count", default: 0, null: false
    t.uuid "pe_calculation_uuid"
    t.uuid "pe_ecosystem_matrix_uuid"
    t.uuid "spe_calculation_uuid"
    t.uuid "spe_ecosystem_matrix_uuid"
    t.datetime "closes_at_ntz"
    t.integer "core_page_ids", default: [], null: false, array: true
    t.datetime "core_steps_completed_at"
    t.datetime "grades_last_published_at"
    t.bigint "course_profile_course_id", null: false
    t.integer "role_book_part_job_id"
    t.integer "period_book_part_job_id"
    t.integer "ungraded_step_count", default: 0, null: false
    t.integer "gradable_step_count", default: 0, null: false
    t.float "available_points", default: 0.0, null: false
    t.float "published_points_before_due", default: ::Float::NAN, null: false
    t.float "published_points_after_due", default: ::Float::NAN, null: false
    t.boolean "is_provisional_score_before_due", default: false, null: false
    t.boolean "is_provisional_score_after_due", default: false, null: false
    t.index ["content_ecosystem_id"], name: "index_tasks_tasks_on_content_ecosystem_id"
    t.index ["course_profile_course_id"], name: "index_tasks_tasks_on_course_profile_course_id"
    t.index ["due_at_ntz", "opens_at_ntz"], name: "index_tasks_tasks_on_due_at_ntz_and_opens_at_ntz"
    t.index ["hidden_at"], name: "index_tasks_tasks_on_hidden_at"
    t.index ["last_worked_at"], name: "index_tasks_tasks_on_last_worked_at"
    t.index ["opens_at_ntz"], name: "index_tasks_tasks_on_opens_at_ntz"
    t.index ["task_type", "created_at"], name: "index_tasks_tasks_on_task_type_and_created_at"
    t.index ["tasks_task_plan_id"], name: "index_tasks_tasks_on_tasks_task_plan_id"
    t.index ["uuid"], name: "index_tasks_tasks_on_uuid", unique: true
  end

  create_table "user_administrators", id: :serial, force: :cascade do |t|
    t.integer "user_profile_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_profile_id"], name: "index_user_administrators_on_user_profile_id", unique: true
  end

  create_table "user_content_analysts", id: :serial, force: :cascade do |t|
    t.integer "user_profile_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_profile_id"], name: "index_user_content_analysts_on_user_profile_id", unique: true
  end

  create_table "user_customer_services", id: :serial, force: :cascade do |t|
    t.integer "user_profile_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_profile_id"], name: "index_user_customer_services_on_user_profile_id", unique: true
  end

  create_table "user_profiles", id: :serial, force: :cascade do |t|
    t.integer "account_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "ui_settings"
    t.index ["account_id"], name: "index_user_profiles_on_account_id", unique: true
  end

  create_table "user_researchers", id: :serial, force: :cascade do |t|
    t.integer "user_profile_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_profile_id"], name: "index_user_researchers_on_user_profile_id", unique: true
  end

  create_table "user_suggestions", force: :cascade do |t|
    t.text "content", null: false
    t.integer "topic", default: 0, null: false
    t.bigint "user_profile_id", null: false
    t.index ["user_profile_id"], name: "index_user_suggestions_on_user_profile_id"
  end

  create_table "user_tour_views", id: :serial, force: :cascade do |t|
    t.integer "view_count", default: 0, null: false
    t.integer "user_profile_id", null: false
    t.integer "user_tour_id", null: false
    t.index ["user_profile_id", "user_tour_id"], name: "index_user_tour_views_on_user_profile_id_and_user_tour_id", unique: true
    t.index ["user_tour_id"], name: "index_user_tour_views_on_user_tour_id"
  end

  create_table "user_tours", id: :serial, force: :cascade do |t|
    t.text "identifier", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["identifier"], name: "index_user_tours_on_identifier", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "catalog_offerings", "content_ecosystems", on_update: :cascade, on_delete: :nullify
  add_foreign_key "content_books", "content_ecosystems", on_update: :cascade, on_delete: :cascade
  add_foreign_key "content_exercise_tags", "content_exercises", on_update: :cascade, on_delete: :cascade
  add_foreign_key "content_exercise_tags", "content_tags", on_update: :cascade, on_delete: :cascade
  add_foreign_key "content_exercises", "content_exercises", column: "derived_from_id"
  add_foreign_key "content_exercises", "content_pages", on_update: :cascade, on_delete: :cascade
  add_foreign_key "content_lo_teks_tags", "content_tags", column: "lo_id", on_update: :cascade, on_delete: :cascade
  add_foreign_key "content_lo_teks_tags", "content_tags", column: "teks_id", on_update: :cascade, on_delete: :cascade
  add_foreign_key "content_maps", "content_ecosystems", column: "content_from_ecosystem_id", on_update: :cascade, on_delete: :cascade
  add_foreign_key "content_maps", "content_ecosystems", column: "content_to_ecosystem_id", on_update: :cascade, on_delete: :cascade
  add_foreign_key "content_notes", "content_pages", on_update: :cascade, on_delete: :cascade
  add_foreign_key "content_notes", "entity_roles", on_update: :cascade, on_delete: :cascade
  add_foreign_key "content_page_tags", "content_pages", on_update: :cascade, on_delete: :cascade
  add_foreign_key "content_page_tags", "content_tags", on_update: :cascade, on_delete: :cascade
  add_foreign_key "content_pages", "content_books", on_update: :cascade, on_delete: :cascade
  add_foreign_key "content_tags", "content_ecosystems", on_update: :cascade, on_delete: :cascade
  add_foreign_key "course_content_course_ecosystems", "content_ecosystems", on_update: :cascade, on_delete: :cascade
  add_foreign_key "course_content_course_ecosystems", "course_profile_courses", on_update: :cascade, on_delete: :cascade
  add_foreign_key "course_content_excluded_exercises", "course_profile_courses", on_update: :cascade, on_delete: :cascade
  add_foreign_key "course_membership_enrollment_changes", "course_membership_enrollments", on_update: :cascade, on_delete: :nullify
  add_foreign_key "course_membership_enrollment_changes", "course_membership_periods", on_update: :cascade, on_delete: :cascade
  add_foreign_key "course_membership_enrollment_changes", "user_profiles", on_update: :cascade, on_delete: :cascade
  add_foreign_key "course_membership_enrollments", "course_membership_periods", on_update: :cascade, on_delete: :cascade
  add_foreign_key "course_membership_enrollments", "course_membership_students", on_update: :cascade, on_delete: :cascade
  add_foreign_key "course_membership_periods", "course_profile_courses", on_update: :cascade, on_delete: :cascade
  add_foreign_key "course_membership_students", "course_profile_courses", on_update: :cascade, on_delete: :cascade
  add_foreign_key "course_membership_students", "entity_roles", on_update: :cascade, on_delete: :cascade
  add_foreign_key "course_membership_teacher_students", "course_membership_periods", on_update: :cascade, on_delete: :cascade
  add_foreign_key "course_membership_teacher_students", "course_profile_courses", on_update: :cascade, on_delete: :cascade
  add_foreign_key "course_membership_teacher_students", "entity_roles", on_update: :cascade, on_delete: :cascade
  add_foreign_key "course_membership_teachers", "course_profile_courses", on_update: :cascade, on_delete: :cascade
  add_foreign_key "course_membership_teachers", "entity_roles", on_update: :cascade, on_delete: :cascade
  add_foreign_key "course_profile_caches", "course_profile_courses", on_update: :cascade, on_delete: :cascade
  add_foreign_key "course_profile_courses", "catalog_offerings", on_update: :cascade, on_delete: :nullify
  add_foreign_key "course_profile_courses", "course_profile_courses", column: "cloned_from_id", on_update: :cascade, on_delete: :nullify
  add_foreign_key "course_profile_courses", "environments", on_update: :cascade, on_delete: :restrict
  add_foreign_key "course_profile_courses", "school_district_schools", on_update: :cascade, on_delete: :nullify
  add_foreign_key "entity_roles", "user_profiles", on_update: :cascade, on_delete: :cascade
  add_foreign_key "lms_contexts", "course_profile_courses", on_update: :cascade, on_delete: :cascade
  add_foreign_key "lms_contexts", "lms_tool_consumers", on_update: :cascade, on_delete: :cascade
  add_foreign_key "lms_course_score_callbacks", "course_profile_courses", on_update: :cascade, on_delete: :cascade
  add_foreign_key "lms_course_score_callbacks", "user_profiles", on_update: :cascade, on_delete: :cascade
  add_foreign_key "lms_nonces", "lms_apps", on_update: :cascade, on_delete: :cascade
  add_foreign_key "oauth_access_grants", "oauth_applications", column: "application_id"
  add_foreign_key "oauth_access_tokens", "oauth_applications", column: "application_id"
  add_foreign_key "ratings_period_book_parts", "course_membership_periods", on_update: :cascade, on_delete: :cascade
  add_foreign_key "ratings_role_book_parts", "entity_roles", on_update: :cascade, on_delete: :cascade
  add_foreign_key "research_cohort_members", "course_membership_students", on_update: :cascade, on_delete: :cascade
  add_foreign_key "research_cohort_members", "research_cohorts", on_update: :cascade, on_delete: :cascade
  add_foreign_key "research_cohorts", "research_studies", on_update: :cascade, on_delete: :cascade
  add_foreign_key "research_manipulations", "research_cohorts", on_update: :cascade, on_delete: :nullify
  add_foreign_key "research_manipulations", "research_studies", on_update: :cascade, on_delete: :cascade
  add_foreign_key "research_manipulations", "research_study_brains", on_update: :cascade, on_delete: :nullify
  add_foreign_key "research_study_brains", "research_studies", on_update: :cascade, on_delete: :cascade
  add_foreign_key "research_study_courses", "course_profile_courses", on_update: :cascade, on_delete: :cascade
  add_foreign_key "research_study_courses", "research_studies", on_update: :cascade, on_delete: :cascade
  add_foreign_key "research_survey_plans", "research_studies", on_update: :cascade, on_delete: :cascade
  add_foreign_key "research_surveys", "course_membership_students", on_update: :cascade, on_delete: :cascade
  add_foreign_key "research_surveys", "research_survey_plans", on_update: :cascade, on_delete: :cascade
  add_foreign_key "school_district_schools", "school_district_districts", on_update: :cascade, on_delete: :nullify
  add_foreign_key "tasks_concept_coach_tasks", "content_pages", on_update: :cascade, on_delete: :cascade
  add_foreign_key "tasks_concept_coach_tasks", "entity_roles", on_update: :cascade, on_delete: :cascade
  add_foreign_key "tasks_concept_coach_tasks", "tasks_tasks", on_update: :cascade, on_delete: :cascade
  add_foreign_key "tasks_course_assistants", "course_profile_courses", on_update: :cascade, on_delete: :cascade
  add_foreign_key "tasks_course_assistants", "tasks_assistants", on_update: :cascade, on_delete: :cascade
  add_foreign_key "tasks_dropped_questions", "tasks_task_plans", on_update: :cascade, on_delete: :cascade
  add_foreign_key "tasks_extensions", "entity_roles", on_update: :cascade, on_delete: :cascade
  add_foreign_key "tasks_extensions", "tasks_task_plans", on_update: :cascade, on_delete: :cascade
  add_foreign_key "tasks_grading_templates", "tasks_grading_templates", column: "cloned_from_id", on_update: :cascade, on_delete: :nullify
  add_foreign_key "tasks_performance_report_exports", "course_profile_courses", on_update: :cascade, on_delete: :cascade
  add_foreign_key "tasks_performance_report_exports", "entity_roles", on_update: :cascade, on_delete: :cascade
  add_foreign_key "tasks_practice_questions", "content_exercises", on_update: :cascade, on_delete: :cascade
  add_foreign_key "tasks_practice_questions", "entity_roles", on_update: :cascade, on_delete: :cascade
  add_foreign_key "tasks_practice_questions", "tasks_tasked_exercises", on_update: :cascade, on_delete: :cascade
  add_foreign_key "tasks_task_plans", "content_ecosystems", on_update: :cascade, on_delete: :cascade
  add_foreign_key "tasks_task_plans", "tasks_assistants", on_update: :cascade, on_delete: :cascade
  add_foreign_key "tasks_task_plans", "tasks_grading_templates", on_update: :cascade, on_delete: :restrict
  add_foreign_key "tasks_task_plans", "tasks_task_plans", column: "cloned_from_id", on_update: :cascade, on_delete: :nullify
  add_foreign_key "tasks_task_steps", "tasks_tasks", on_update: :cascade, on_delete: :cascade
  add_foreign_key "tasks_tasked_exercises", "content_exercises", on_update: :cascade, on_delete: :cascade
  add_foreign_key "tasks_tasking_plans", "tasks_task_plans", on_update: :cascade, on_delete: :cascade
  add_foreign_key "tasks_taskings", "entity_roles", on_update: :cascade, on_delete: :cascade
  add_foreign_key "tasks_taskings", "tasks_tasks", on_update: :cascade, on_delete: :cascade
  add_foreign_key "tasks_tasks", "content_ecosystems", on_update: :cascade, on_delete: :cascade
  add_foreign_key "tasks_tasks", "course_profile_courses", on_update: :cascade, on_delete: :cascade
  add_foreign_key "tasks_tasks", "tasks_task_plans", on_update: :cascade, on_delete: :cascade
  add_foreign_key "user_administrators", "user_profiles", on_update: :cascade, on_delete: :cascade
  add_foreign_key "user_content_analysts", "user_profiles", on_update: :cascade, on_delete: :cascade
  add_foreign_key "user_customer_services", "user_profiles", on_update: :cascade, on_delete: :cascade
  add_foreign_key "user_profiles", "openstax_accounts_accounts", column: "account_id", on_update: :cascade, on_delete: :cascade
  add_foreign_key "user_researchers", "user_profiles", on_update: :cascade, on_delete: :cascade
  add_foreign_key "user_suggestions", "user_profiles", on_update: :cascade, on_delete: :cascade
  add_foreign_key "user_tour_views", "user_profiles"
  add_foreign_key "user_tour_views", "user_tours"
end
