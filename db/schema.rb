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

ActiveRecord::Schema.define(version: 20181018152101) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"
  enable_extension "hstore"
  enable_extension "pgcrypto"
  enable_extension "citext"

  create_table "catalog_offerings", force: :cascade do |t|
    t.string   "salesforce_book_name",                 null: false
    t.integer  "content_ecosystem_id"
    t.boolean  "is_tutor",             default: false, null: false
    t.boolean  "is_concept_coach",     default: false, null: false
    t.string   "description",                          null: false
    t.string   "webview_url",                          null: false
    t.string   "pdf_url",                              null: false
    t.datetime "created_at",                           null: false
    t.datetime "updated_at",                           null: false
    t.string   "default_course_name"
    t.string   "appearance_code"
    t.boolean  "is_available",                         null: false
    t.string   "title",                                null: false
    t.integer  "number",                               null: false
    t.boolean  "does_cost",            default: false, null: false
  end

  add_index "catalog_offerings", ["content_ecosystem_id"], name: "index_catalog_offerings_on_content_ecosystem_id", using: :btree
  add_index "catalog_offerings", ["number"], name: "index_catalog_offerings_on_number", unique: true, using: :btree
  add_index "catalog_offerings", ["salesforce_book_name"], name: "index_catalog_offerings_on_salesforce_book_name", using: :btree
  add_index "catalog_offerings", ["title"], name: "index_catalog_offerings_on_title", using: :btree

  create_table "content_books", force: :cascade do |t|
    t.string   "url",                                                           null: false
    t.text     "content"
    t.integer  "content_ecosystem_id",                                          null: false
    t.string   "title",                                                         null: false
    t.string   "uuid",                                                          null: false
    t.string   "version",                                                       null: false
    t.datetime "created_at",                                                    null: false
    t.datetime "updated_at",                                                    null: false
    t.string   "short_id"
    t.text     "reading_processing_instructions", default: "[]",                null: false
    t.uuid     "tutor_uuid",                      default: "gen_random_uuid()"
  end

  add_index "content_books", ["content_ecosystem_id"], name: "index_content_books_on_content_ecosystem_id", using: :btree
  add_index "content_books", ["title"], name: "index_content_books_on_title", using: :btree
  add_index "content_books", ["tutor_uuid"], name: "index_content_books_on_tutor_uuid", unique: true, using: :btree
  add_index "content_books", ["url"], name: "index_content_books_on_url", using: :btree

  create_table "content_chapters", force: :cascade do |t|
    t.integer  "content_book_id",                                             null: false
    t.integer  "number",                                                      null: false
    t.string   "title",                                                       null: false
    t.datetime "created_at",                                                  null: false
    t.datetime "updated_at",                                                  null: false
    t.integer  "content_all_exercises_pool_id"
    t.text     "book_location",                 default: "[]",                null: false
    t.uuid     "tutor_uuid",                    default: "gen_random_uuid()"
  end

  add_index "content_chapters", ["content_book_id", "number"], name: "index_content_chapters_on_content_book_id_and_number", unique: true, using: :btree
  add_index "content_chapters", ["title"], name: "index_content_chapters_on_title", using: :btree
  add_index "content_chapters", ["tutor_uuid"], name: "index_content_chapters_on_tutor_uuid", unique: true, using: :btree

  create_table "content_ecosystems", force: :cascade do |t|
    t.string   "title",                                         null: false
    t.datetime "created_at",                                    null: false
    t.datetime "updated_at",                                    null: false
    t.text     "comments"
    t.uuid     "tutor_uuid",      default: "gen_random_uuid()"
    t.integer  "sequence_number", default: 0,                   null: false
    t.datetime "deleted_at"
  end

  add_index "content_ecosystems", ["created_at"], name: "index_content_ecosystems_on_created_at", using: :btree
  add_index "content_ecosystems", ["title"], name: "index_content_ecosystems_on_title", using: :btree
  add_index "content_ecosystems", ["tutor_uuid"], name: "index_content_ecosystems_on_tutor_uuid", unique: true, using: :btree

  create_table "content_exercise_tags", force: :cascade do |t|
    t.integer  "content_exercise_id", null: false
    t.integer  "content_tag_id",      null: false
    t.datetime "created_at",          null: false
    t.datetime "updated_at",          null: false
  end

  add_index "content_exercise_tags", ["content_exercise_id", "content_tag_id"], name: "index_content_exercise_tags_on_c_e_id_and_c_t_id", unique: true, using: :btree
  add_index "content_exercise_tags", ["content_tag_id"], name: "index_content_exercise_tags_on_content_tag_id", using: :btree

  create_table "content_exercises", force: :cascade do |t|
    t.string   "url",                             null: false
    t.text     "content"
    t.integer  "content_page_id",                 null: false
    t.integer  "number",                          null: false
    t.integer  "version",                         null: false
    t.string   "title"
    t.datetime "created_at",                      null: false
    t.datetime "updated_at",                      null: false
    t.text     "preview"
    t.text     "context"
    t.boolean  "has_interactive", default: false, null: false
    t.boolean  "has_video",       default: false, null: false
    t.uuid     "uuid",                            null: false
    t.uuid     "group_uuid",                      null: false
    t.string   "nickname"
  end

  add_index "content_exercises", ["content_page_id"], name: "index_content_exercises_on_content_page_id", using: :btree
  add_index "content_exercises", ["group_uuid", "version"], name: "index_content_exercises_on_group_uuid_and_version", using: :btree
  add_index "content_exercises", ["number", "version"], name: "index_content_exercises_on_number_and_version", using: :btree
  add_index "content_exercises", ["title"], name: "index_content_exercises_on_title", using: :btree
  add_index "content_exercises", ["url"], name: "index_content_exercises_on_url", using: :btree
  add_index "content_exercises", ["uuid"], name: "index_content_exercises_on_uuid", using: :btree

  create_table "content_lo_teks_tags", force: :cascade do |t|
    t.integer  "lo_id",      null: false
    t.integer  "teks_id",    null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_index "content_lo_teks_tags", ["lo_id", "teks_id"], name: "content_lo_teks_tag_lo_teks_uniq", unique: true, using: :btree

  create_table "content_maps", force: :cascade do |t|
    t.integer  "content_from_ecosystem_id",                            null: false
    t.integer  "content_to_ecosystem_id",                              null: false
    t.boolean  "is_valid",                                             null: false
    t.datetime "created_at",                                           null: false
    t.datetime "updated_at",                                           null: false
    t.text     "exercise_id_to_page_id_map",            default: "{}", null: false
    t.text     "page_id_to_page_id_map",                default: "{}", null: false
    t.text     "page_id_to_pool_type_exercise_ids_map", default: "{}", null: false
    t.text     "validity_error_messages",               default: "[]", null: false
  end

  add_index "content_maps", ["content_from_ecosystem_id", "content_to_ecosystem_id"], name: "index_content_maps_on_from_ecosystem_id_and_to_ecosystem_id", unique: true, using: :btree
  add_index "content_maps", ["content_to_ecosystem_id"], name: "index_content_maps_on_content_to_ecosystem_id", using: :btree

  create_table "content_page_tags", force: :cascade do |t|
    t.integer  "content_page_id", null: false
    t.integer  "content_tag_id",  null: false
    t.datetime "created_at",      null: false
    t.datetime "updated_at",      null: false
  end

  add_index "content_page_tags", ["content_page_id", "content_tag_id"], name: "index_content_page_tags_on_content_page_id_and_content_tag_id", unique: true, using: :btree
  add_index "content_page_tags", ["content_tag_id"], name: "index_content_page_tags_on_content_tag_id", using: :btree

  create_table "content_pages", force: :cascade do |t|
    t.string   "url",                                                            null: false
    t.text     "content"
    t.integer  "content_chapter_id",                                             null: false
    t.integer  "content_reading_dynamic_pool_id"
    t.integer  "content_reading_context_pool_id"
    t.integer  "content_homework_core_pool_id"
    t.integer  "content_homework_dynamic_pool_id"
    t.integer  "content_practice_widget_pool_id"
    t.integer  "number",                                                         null: false
    t.string   "title",                                                          null: false
    t.string   "uuid",                                                           null: false
    t.string   "version",                                                        null: false
    t.datetime "created_at",                                                     null: false
    t.datetime "updated_at",                                                     null: false
    t.integer  "content_all_exercises_pool_id"
    t.integer  "content_concept_coach_pool_id"
    t.string   "short_id"
    t.text     "book_location",                    default: "[]",                null: false
    t.text     "fragments",                        default: "[]",                null: false
    t.text     "snap_labs",                        default: "[]",                null: false
    t.uuid     "tutor_uuid",                       default: "gen_random_uuid()"
  end

  add_index "content_pages", ["content_chapter_id", "number"], name: "index_content_pages_on_content_chapter_id_and_number", unique: true, using: :btree
  add_index "content_pages", ["title"], name: "index_content_pages_on_title", using: :btree
  add_index "content_pages", ["tutor_uuid"], name: "index_content_pages_on_tutor_uuid", unique: true, using: :btree
  add_index "content_pages", ["url"], name: "index_content_pages_on_url", using: :btree

  create_table "content_pools", force: :cascade do |t|
    t.integer  "content_ecosystem_id",                null: false
    t.string   "uuid",                                null: false
    t.integer  "pool_type",                           null: false
    t.datetime "created_at",                          null: false
    t.datetime "updated_at",                          null: false
    t.text     "content_exercise_ids", default: "[]", null: false
  end

  add_index "content_pools", ["content_ecosystem_id"], name: "index_content_pools_on_content_ecosystem_id", using: :btree
  add_index "content_pools", ["pool_type"], name: "index_content_pools_on_pool_type", using: :btree
  add_index "content_pools", ["uuid"], name: "index_content_pools_on_uuid", unique: true, using: :btree

  create_table "content_tags", force: :cascade do |t|
    t.integer  "content_ecosystem_id",             null: false
    t.string   "value",                            null: false
    t.integer  "tag_type",             default: 0, null: false
    t.string   "name"
    t.text     "description"
    t.string   "data"
    t.boolean  "visible"
    t.datetime "created_at",                       null: false
    t.datetime "updated_at",                       null: false
  end

  add_index "content_tags", ["content_ecosystem_id"], name: "index_content_tags_on_content_ecosystem_id", using: :btree
  add_index "content_tags", ["tag_type"], name: "index_content_tags_on_tag_type", using: :btree
  add_index "content_tags", ["value", "content_ecosystem_id"], name: "index_content_tags_on_value_and_content_ecosystem_id", unique: true, using: :btree

  create_table "course_content_course_ecosystems", force: :cascade do |t|
    t.integer  "course_profile_course_id", null: false
    t.integer  "content_ecosystem_id",     null: false
    t.datetime "created_at",               null: false
    t.datetime "updated_at",               null: false
  end

  add_index "course_content_course_ecosystems", ["content_ecosystem_id", "course_profile_course_id"], name: "course_ecosystems_on_ecosystem_id_course_id", using: :btree
  add_index "course_content_course_ecosystems", ["course_profile_course_id", "created_at"], name: "course_ecosystems_on_course_id_created_at", using: :btree

  create_table "course_content_excluded_exercises", force: :cascade do |t|
    t.integer  "course_profile_course_id", null: false
    t.integer  "exercise_number",          null: false
    t.datetime "created_at",               null: false
    t.datetime "updated_at",               null: false
  end

  add_index "course_content_excluded_exercises", ["course_profile_course_id"], name: "index_c_c_excluded_exercises_on_c_p_course_id", using: :btree
  add_index "course_content_excluded_exercises", ["exercise_number", "course_profile_course_id"], name: "index_excluded_exercises_on_number_and_course_id", unique: true, using: :btree

  create_table "course_membership_enrollment_changes", force: :cascade do |t|
    t.integer  "user_profile_id",                                            null: false
    t.integer  "course_membership_enrollment_id"
    t.integer  "course_membership_period_id",                                null: false
    t.integer  "status",                                      default: 0,    null: false
    t.boolean  "requires_enrollee_approval",                  default: true, null: false
    t.datetime "enrollee_approved_at"
    t.datetime "created_at",                                                 null: false
    t.datetime "updated_at",                                                 null: false
    t.integer  "course_membership_conflicting_enrollment_id"
  end

  add_index "course_membership_enrollment_changes", ["course_membership_conflicting_enrollment_id"], name: "index_c_m_enrollment_changes_on_c_m_conflicting_enrollment_id", using: :btree
  add_index "course_membership_enrollment_changes", ["course_membership_enrollment_id"], name: "index_course_membership_enrollments_on_enrollment_id", using: :btree
  add_index "course_membership_enrollment_changes", ["course_membership_period_id"], name: "index_course_membership_enrollment_changes_on_period_id", using: :btree
  add_index "course_membership_enrollment_changes", ["user_profile_id"], name: "index_course_membership_enrollment_changes_on_user_profile_id", using: :btree

  create_table "course_membership_enrollments", force: :cascade do |t|
    t.integer  "course_membership_period_id",  null: false
    t.integer  "course_membership_student_id", null: false
    t.datetime "created_at",                   null: false
    t.datetime "updated_at",                   null: false
    t.integer  "sequence_number",              null: false
  end

  add_index "course_membership_enrollments", ["course_membership_period_id", "course_membership_student_id"], name: "course_membership_enrollments_period_student", using: :btree
  add_index "course_membership_enrollments", ["course_membership_student_id", "sequence_number"], name: "index_enrollments_on_student_id_and_sequence_number", unique: true, using: :btree

  create_table "course_membership_periods", force: :cascade do |t|
    t.integer  "course_profile_course_id",                                     null: false
    t.string   "name",                                                         null: false
    t.datetime "created_at",                                                   null: false
    t.datetime "updated_at",                                                   null: false
    t.string   "enrollment_code",                                              null: false
    t.datetime "archived_at"
    t.string   "default_open_time"
    t.string   "default_due_time"
    t.integer  "entity_teacher_student_role_id",                               null: false
    t.uuid     "uuid",                           default: "gen_random_uuid()"
  end

  add_index "course_membership_periods", ["archived_at"], name: "index_course_membership_periods_on_archived_at", using: :btree
  add_index "course_membership_periods", ["course_profile_course_id"], name: "index_course_membership_periods_on_course_profile_course_id", using: :btree
  add_index "course_membership_periods", ["enrollment_code"], name: "index_course_membership_periods_on_enrollment_code", unique: true, using: :btree
  add_index "course_membership_periods", ["entity_teacher_student_role_id"], name: "index_c_m_periods_on_e_teacher_student_role_id", unique: true, using: :btree
  add_index "course_membership_periods", ["name", "course_profile_course_id"], name: "index_c_m_periods_on_name_and_c_p_course_id", using: :btree
  add_index "course_membership_periods", ["uuid"], name: "index_course_membership_periods_on_uuid", unique: true, using: :btree

  create_table "course_membership_students", force: :cascade do |t|
    t.integer  "course_profile_course_id",                                  null: false
    t.integer  "entity_role_id",                                            null: false
    t.datetime "dropped_at"
    t.datetime "created_at",                                                null: false
    t.datetime "updated_at",                                                null: false
    t.string   "student_identifier"
    t.uuid     "uuid",                        default: "gen_random_uuid()"
    t.datetime "first_paid_at"
    t.boolean  "is_paid",                     default: false,               null: false
    t.boolean  "is_comped",                   default: false,               null: false
    t.datetime "payment_due_at",                                            null: false
    t.boolean  "is_refund_pending",           default: false,               null: false
    t.jsonb    "refund_survey_response",      default: {}
    t.integer  "course_membership_period_id",                               null: false
  end

  add_index "course_membership_students", ["course_profile_course_id", "student_identifier"], name: "index_course_membership_students_on_c_p_c_id_and_s_identifier", using: :btree
  add_index "course_membership_students", ["dropped_at"], name: "index_course_membership_students_on_dropped_at", using: :btree
  add_index "course_membership_students", ["entity_role_id"], name: "index_course_membership_students_on_entity_role_id", unique: true, using: :btree
  add_index "course_membership_students", ["uuid"], name: "index_course_membership_students_on_uuid", unique: true, using: :btree

  create_table "course_membership_teachers", force: :cascade do |t|
    t.integer  "course_profile_course_id", null: false
    t.integer  "entity_role_id",           null: false
    t.datetime "created_at",               null: false
    t.datetime "updated_at",               null: false
    t.datetime "deleted_at"
  end

  add_index "course_membership_teachers", ["course_profile_course_id"], name: "index_course_membership_teachers_on_course_profile_course_id", using: :btree
  add_index "course_membership_teachers", ["entity_role_id"], name: "index_course_membership_teachers_on_entity_role_id", unique: true, using: :btree

  create_table "course_profile_courses", force: :cascade do |t|
    t.integer  "school_district_school_id"
    t.string   "name",                                                                                               null: false
    t.datetime "created_at",                                                                                         null: false
    t.datetime "updated_at",                                                                                         null: false
    t.boolean  "is_concept_coach",                                                                                   null: false
    t.string   "teach_token",                                                                                        null: false
    t.integer  "catalog_offering_id"
    t.string   "appearance_code"
    t.string   "default_open_time"
    t.string   "default_due_time"
    t.integer  "time_zone_id",                                                                                       null: false
    t.boolean  "is_college"
    t.datetime "starts_at",                                                                                          null: false
    t.datetime "ends_at",                                                                                            null: false
    t.integer  "term",                                                                                               null: false
    t.integer  "year",                                                                                               null: false
    t.integer  "cloned_from_id"
    t.boolean  "is_preview",                                                                                         null: false
    t.boolean  "is_excluded_from_salesforce",                                          default: false,               null: false
    t.uuid     "uuid",                                                                 default: "gen_random_uuid()", null: false
    t.integer  "sequence_number",                                                      default: 0,                   null: false
    t.string   "biglearn_student_clues_algorithm_name",                                                              null: false
    t.string   "biglearn_teacher_clues_algorithm_name",                                                              null: false
    t.string   "biglearn_assignment_spes_algorithm_name",                                                            null: false
    t.string   "biglearn_assignment_pes_algorithm_name",                                                             null: false
    t.string   "biglearn_practice_worst_areas_algorithm_name",                                                       null: false
    t.boolean  "is_test",                                                              default: false,               null: false
    t.boolean  "does_cost",                                                            default: false,               null: false
    t.integer  "estimated_student_count"
    t.datetime "preview_claimed_at"
    t.boolean  "is_preview_ready",                                                     default: false,               null: false
    t.datetime "deleted_at"
    t.boolean  "is_lms_enabled"
    t.boolean  "is_lms_enabling_allowed",                                              default: false,               null: false
    t.boolean  "is_access_switchable",                                                 default: true,                null: false
    t.string   "last_lms_scores_push_job_id"
    t.string   "creator_campaign_member_id"
    t.string   "latest_adoption_decision"
    t.decimal  "homework_score_weight",                        precision: 3, scale: 2, default: 1.0,                 null: false
    t.decimal  "homework_progress_weight",                     precision: 3, scale: 2, default: 0.0,                 null: false
    t.decimal  "reading_score_weight",                         precision: 3, scale: 2, default: 0.0,                 null: false
    t.decimal  "reading_progress_weight",                      precision: 3, scale: 2, default: 0.0,                 null: false
  end

  add_index "course_profile_courses", ["catalog_offering_id"], name: "index_course_profile_courses_on_catalog_offering_id", using: :btree
  add_index "course_profile_courses", ["cloned_from_id"], name: "index_course_profile_courses_on_cloned_from_id", using: :btree
  add_index "course_profile_courses", ["is_lms_enabling_allowed"], name: "index_course_profile_courses_on_is_lms_enabling_allowed", using: :btree
  add_index "course_profile_courses", ["is_preview", "is_preview_ready", "preview_claimed_at", "catalog_offering_id"], name: "preview_pending_index", using: :btree
  add_index "course_profile_courses", ["name"], name: "index_course_profile_courses_on_name", using: :btree
  add_index "course_profile_courses", ["school_district_school_id"], name: "index_course_profile_courses_on_school_district_school_id", using: :btree
  add_index "course_profile_courses", ["teach_token"], name: "index_course_profile_courses_on_teach_token", unique: true, using: :btree
  add_index "course_profile_courses", ["time_zone_id"], name: "index_course_profile_courses_on_time_zone_id", unique: true, using: :btree
  add_index "course_profile_courses", ["uuid"], name: "index_course_profile_courses_on_uuid", unique: true, using: :btree
  add_index "course_profile_courses", ["year", "term"], name: "index_course_profile_courses_on_year_and_term", using: :btree

  create_table "delayed_jobs", force: :cascade do |t|
    t.integer  "priority",   default: 0, null: false
    t.integer  "attempts",   default: 0, null: false
    t.text     "handler",                null: false
    t.text     "last_error"
    t.datetime "run_at"
    t.datetime "locked_at"
    t.datetime "failed_at"
    t.string   "locked_by"
    t.string   "queue"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "delayed_jobs", ["priority", "run_at"], name: "delayed_jobs_priority", using: :btree

  create_table "entity_roles", force: :cascade do |t|
    t.integer  "role_type",           default: 0, null: false
    t.datetime "created_at",                      null: false
    t.datetime "updated_at",                      null: false
    t.string   "research_identifier",             null: false
  end

  add_index "entity_roles", ["research_identifier"], name: "index_entity_roles_on_research_identifier", unique: true, using: :btree
  add_index "entity_roles", ["role_type"], name: "index_entity_roles_on_role_type", using: :btree

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
    t.integer  "contract_id",                 null: false
    t.integer  "user_id",                     null: false
    t.string   "user_type",                   null: false
    t.datetime "created_at",                  null: false
    t.datetime "updated_at",                  null: false
    t.boolean  "is_implicit", default: false, null: false
  end

  add_index "fine_print_signatures", ["contract_id"], name: "index_fine_print_signatures_on_contract_id", using: :btree
  add_index "fine_print_signatures", ["user_id", "user_type", "contract_id"], name: "index_fine_print_signatures_on_u_id_and_u_type_and_c_id", unique: true, using: :btree

  create_table "legal_targeted_contract_relationships", force: :cascade do |t|
    t.string   "child_gid",  null: false
    t.string   "parent_gid", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_index "legal_targeted_contract_relationships", ["child_gid", "parent_gid"], name: "legal_targeted_contracts_rship_child_parent", unique: true, using: :btree
  add_index "legal_targeted_contract_relationships", ["parent_gid"], name: "legal_targeted_contracts_rship_parent", using: :btree

  create_table "legal_targeted_contracts", force: :cascade do |t|
    t.string   "target_gid",                            null: false
    t.string   "target_name",                           null: false
    t.string   "contract_name",                         null: false
    t.boolean  "is_proxy_signed",       default: false
    t.boolean  "is_end_user_visible",   default: true
    t.datetime "created_at",                            null: false
    t.datetime "updated_at",                            null: false
    t.text     "masked_contract_names", default: "[]",  null: false
  end

  add_index "legal_targeted_contracts", ["target_gid"], name: "legal_targeted_contracts_target", using: :btree

  create_table "lms_apps", force: :cascade do |t|
    t.integer  "owner_id",   null: false
    t.string   "owner_type", null: false
    t.string   "key",        null: false
    t.string   "secret",     null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_index "lms_apps", ["key"], name: "index_lms_apps_on_key", unique: true, using: :btree
  add_index "lms_apps", ["owner_type", "owner_id"], name: "index_lms_apps_on_owner_type_and_owner_id", unique: true, using: :btree

  create_table "lms_contexts", force: :cascade do |t|
    t.string   "lti_id",                   null: false
    t.integer  "lms_tool_consumer_id",     null: false
    t.integer  "course_profile_course_id"
    t.datetime "created_at",               null: false
    t.datetime "updated_at",               null: false
  end

  add_index "lms_contexts", ["course_profile_course_id"], name: "index_lms_contexts_on_course_profile_course_id", unique: true, using: :btree
  add_index "lms_contexts", ["lms_tool_consumer_id"], name: "index_lms_contexts_on_lms_tool_consumer_id", using: :btree
  add_index "lms_contexts", ["lti_id", "lms_tool_consumer_id", "course_profile_course_id"], name: "lms_contexts_lti_id_tool_consumer_id_course_id", unique: true, using: :btree
  add_index "lms_contexts", ["lti_id"], name: "index_lms_contexts_on_lti_id", using: :btree

  create_table "lms_course_score_callbacks", force: :cascade do |t|
    t.string   "result_sourcedid",         null: false
    t.string   "outcome_url",              null: false
    t.integer  "user_profile_id",          null: false
    t.integer  "course_profile_course_id", null: false
    t.datetime "created_at",               null: false
    t.datetime "updated_at",               null: false
    t.string   "resource_link_id",         null: false
  end

  add_index "lms_course_score_callbacks", ["course_profile_course_id", "user_profile_id", "resource_link_id"], name: "course_score_callbacks_on_course_user_link", unique: true, using: :btree
  add_index "lms_course_score_callbacks", ["result_sourcedid", "outcome_url"], name: "course_score_callback_result_outcome", unique: true, using: :btree
  add_index "lms_course_score_callbacks", ["user_profile_id"], name: "course_score_callbacks_on_user", using: :btree

  create_table "lms_nonces", force: :cascade do |t|
    t.string   "value",      limit: 128,             null: false
    t.datetime "created_at",                         null: false
    t.integer  "lms_app_id"
    t.datetime "updated_at",                         null: false
    t.integer  "app_type",               default: 0, null: false
  end

  add_index "lms_nonces", ["lms_app_id"], name: "index_lms_nonces_on_lms_app_id", using: :btree

  create_table "lms_tool_consumers", force: :cascade do |t|
    t.string   "guid",                null: false
    t.string   "product_family_code"
    t.string   "version"
    t.string   "name"
    t.string   "description"
    t.string   "url"
    t.string   "contact_email"
    t.datetime "created_at",          null: false
    t.datetime "updated_at",          null: false
  end

  add_index "lms_tool_consumers", ["guid"], name: "index_lms_tool_consumers_on_guid", unique: true, using: :btree

  create_table "lms_trusted_launch_data", force: :cascade do |t|
    t.json     "request_params"
    t.string   "request_url"
    t.datetime "created_at",     null: false
    t.datetime "updated_at",     null: false
  end

  add_index "lms_trusted_launch_data", ["created_at"], name: "index_lms_trusted_launch_data_on_created_at", using: :btree

  create_table "lms_users", force: :cascade do |t|
    t.string   "lti_user_id",                   null: false
    t.integer  "openstax_accounts_accounts_id"
    t.datetime "created_at",                    null: false
    t.datetime "updated_at",                    null: false
  end

  add_index "lms_users", ["lti_user_id"], name: "index_lms_users_on_lti_user_id", using: :btree
  add_index "lms_users", ["openstax_accounts_accounts_id"], name: "index_lms_users_on_openstax_accounts_accounts_id", using: :btree

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
    t.string   "token",                               null: false
    t.string   "refresh_token"
    t.integer  "expires_in"
    t.datetime "revoked_at"
    t.datetime "created_at",                          null: false
    t.string   "scopes"
    t.string   "previous_refresh_token", default: "", null: false
  end

  add_index "oauth_access_tokens", ["refresh_token"], name: "index_oauth_access_tokens_on_refresh_token", unique: true, using: :btree
  add_index "oauth_access_tokens", ["resource_owner_id"], name: "index_oauth_access_tokens_on_resource_owner_id", using: :btree
  add_index "oauth_access_tokens", ["token"], name: "index_oauth_access_tokens_on_token", unique: true, using: :btree

  create_table "oauth_applications", force: :cascade do |t|
    t.string   "name",                        null: false
    t.string   "uid",                         null: false
    t.string   "secret",                      null: false
    t.text     "redirect_uri",                null: false
    t.string   "scopes",       default: "",   null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "owner_id"
    t.string   "owner_type"
    t.boolean  "confidential", default: true, null: false
  end

  add_index "oauth_applications", ["owner_id", "owner_type"], name: "index_oauth_applications_on_owner_id_and_owner_type", using: :btree
  add_index "oauth_applications", ["uid"], name: "index_oauth_applications_on_uid", unique: true, using: :btree

  create_table "openstax_accounts_accounts", force: :cascade do |t|
    t.integer  "openstax_uid"
    t.string   "username"
    t.string   "access_token"
    t.string   "first_name"
    t.string   "last_name"
    t.string   "full_name"
    t.string   "title"
    t.datetime "created_at",                                          null: false
    t.datetime "updated_at",                                          null: false
    t.integer  "faculty_status",        default: 0,                   null: false
    t.string   "salesforce_contact_id"
    t.uuid     "uuid",                  default: "gen_random_uuid()", null: false
    t.integer  "role",                  default: 0,                   null: false
    t.citext   "support_identifier"
    t.boolean  "is_test"
    t.integer  "school_type",           default: 0,                   null: false
  end

  add_index "openstax_accounts_accounts", ["access_token"], name: "index_openstax_accounts_accounts_on_access_token", unique: true, using: :btree
  add_index "openstax_accounts_accounts", ["faculty_status"], name: "index_openstax_accounts_accounts_on_faculty_status", using: :btree
  add_index "openstax_accounts_accounts", ["first_name"], name: "index_openstax_accounts_accounts_on_first_name", using: :btree
  add_index "openstax_accounts_accounts", ["full_name"], name: "index_openstax_accounts_accounts_on_full_name", using: :btree
  add_index "openstax_accounts_accounts", ["last_name"], name: "index_openstax_accounts_accounts_on_last_name", using: :btree
  add_index "openstax_accounts_accounts", ["openstax_uid"], name: "index_openstax_accounts_accounts_on_openstax_uid", unique: true, using: :btree
  add_index "openstax_accounts_accounts", ["role"], name: "index_openstax_accounts_accounts_on_role", using: :btree
  add_index "openstax_accounts_accounts", ["salesforce_contact_id"], name: "index_openstax_accounts_accounts_on_salesforce_contact_id", using: :btree
  add_index "openstax_accounts_accounts", ["school_type"], name: "index_openstax_accounts_accounts_on_school_type", using: :btree
  add_index "openstax_accounts_accounts", ["support_identifier"], name: "index_openstax_accounts_accounts_on_support_identifier", unique: true, using: :btree
  add_index "openstax_accounts_accounts", ["username"], name: "index_openstax_accounts_accounts_on_username", unique: true, using: :btree
  add_index "openstax_accounts_accounts", ["uuid"], name: "index_openstax_accounts_accounts_on_uuid", unique: true, using: :btree

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

  create_table "openstax_salesforce_users", force: :cascade do |t|
    t.string   "name"
    t.string   "uid",           null: false
    t.string   "oauth_token",   null: false
    t.string   "refresh_token", null: false
    t.string   "instance_url",  null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "research_cohort_members", force: :cascade do |t|
    t.integer  "research_cohort_id",           null: false
    t.integer  "course_membership_student_id", null: false
    t.datetime "created_at",                   null: false
    t.datetime "updated_at",                   null: false
  end

  add_index "research_cohort_members", ["course_membership_student_id"], name: "index_research_cohort_members_on_course_membership_student_id", using: :btree
  add_index "research_cohort_members", ["research_cohort_id", "course_membership_student_id"], name: "index_cohort_members_on_cohort_and_student", unique: true, using: :btree
  add_index "research_cohort_members", ["research_cohort_id"], name: "index_research_cohort_members_on_research_cohort_id", using: :btree

  create_table "research_cohorts", force: :cascade do |t|
    t.integer  "research_study_id",                   null: false
    t.string   "name",                                null: false
    t.integer  "cohort_members_count", default: 0,    null: false
    t.boolean  "is_accepting_members", default: true, null: false
    t.datetime "created_at",                          null: false
    t.datetime "updated_at",                          null: false
  end

  add_index "research_cohorts", ["research_study_id"], name: "index_research_cohorts_on_research_study_id", using: :btree

  create_table "research_manipulations", force: :cascade do |t|
    t.integer  "research_study_id",                    null: false
    t.integer  "research_cohort_id"
    t.integer  "research_study_brain_id"
    t.integer  "target_id"
    t.string   "target_type"
    t.jsonb    "context",                 default: {}, null: false
    t.datetime "created_at"
  end

  add_index "research_manipulations", ["research_cohort_id"], name: "index_research_manipulations_on_research_cohort_id", using: :btree
  add_index "research_manipulations", ["research_study_brain_id"], name: "index_research_manipulations_on_research_study_brain_id", using: :btree
  add_index "research_manipulations", ["research_study_id"], name: "index_research_manipulations_on_research_study_id", using: :btree

  create_table "research_studies", force: :cascade do |t|
    t.string   "name",                null: false
    t.text     "description"
    t.datetime "created_at",          null: false
    t.datetime "updated_at",          null: false
    t.datetime "activate_at"
    t.datetime "deactivate_at"
    t.datetime "last_activated_at"
    t.datetime "last_deactivated_at"
  end

  add_index "research_studies", ["last_activated_at"], name: "index_research_studies_on_last_activated_at", using: :btree
  add_index "research_studies", ["last_deactivated_at"], name: "index_research_studies_on_last_deactivated_at", using: :btree

  create_table "research_study_brains", force: :cascade do |t|
    t.integer "research_study_id", null: false
    t.text    "name",              null: false
    t.text    "type",              null: false
    t.text    "code",              null: false
  end

  add_index "research_study_brains", ["research_study_id"], name: "index_research_study_brains_on_research_study_id", using: :btree

  create_table "research_study_courses", force: :cascade do |t|
    t.integer  "research_study_id",        null: false
    t.integer  "course_profile_course_id", null: false
    t.datetime "created_at",               null: false
    t.datetime "updated_at",               null: false
  end

  add_index "research_study_courses", ["course_profile_course_id", "research_study_id"], name: "research_study_courses_on_course_and_study", unique: true, using: :btree
  add_index "research_study_courses", ["course_profile_course_id"], name: "index_research_study_courses_on_course_profile_course_id", using: :btree
  add_index "research_study_courses", ["research_study_id"], name: "index_research_study_courses_on_research_study_id", using: :btree

  create_table "research_survey_plans", force: :cascade do |t|
    t.integer  "research_study_id",     null: false
    t.string   "title_for_researchers", null: false
    t.string   "title_for_students",    null: false
    t.text     "description"
    t.text     "survey_js_model"
    t.datetime "published_at"
    t.datetime "hidden_at"
    t.datetime "created_at",            null: false
    t.datetime "updated_at",            null: false
  end

  add_index "research_survey_plans", ["hidden_at"], name: "index_research_survey_plans_on_hidden_at", using: :btree
  add_index "research_survey_plans", ["published_at"], name: "index_research_survey_plans_on_published_at", using: :btree
  add_index "research_survey_plans", ["research_study_id"], name: "index_research_survey_plans_on_research_study_id", using: :btree

  create_table "research_surveys", force: :cascade do |t|
    t.integer  "research_survey_plan_id",      null: false
    t.integer  "course_membership_student_id", null: false
    t.jsonb    "survey_js_response"
    t.datetime "completed_at"
    t.datetime "hidden_at"
    t.datetime "created_at",                   null: false
    t.datetime "updated_at",                   null: false
    t.datetime "deleted_at"
  end

  add_index "research_surveys", ["completed_at"], name: "index_research_surveys_on_completed_at", using: :btree
  add_index "research_surveys", ["course_membership_student_id", "research_survey_plan_id"], name: "research_surveys_on_student_and_plan", unique: true, using: :btree
  add_index "research_surveys", ["course_membership_student_id"], name: "research_surveys_on_student", using: :btree
  add_index "research_surveys", ["deleted_at"], name: "index_research_surveys_on_deleted_at", using: :btree
  add_index "research_surveys", ["hidden_at"], name: "index_research_surveys_on_hidden_at", using: :btree
  add_index "research_surveys", ["research_survey_plan_id"], name: "index_research_surveys_on_research_survey_plan_id", using: :btree

  create_table "role_role_users", force: :cascade do |t|
    t.integer  "user_profile_id", null: false
    t.integer  "entity_role_id",  null: false
    t.datetime "created_at",      null: false
    t.datetime "updated_at",      null: false
  end

  add_index "role_role_users", ["user_profile_id", "entity_role_id"], name: "role_role_users_user_role_uniq", unique: true, using: :btree

  create_table "school_district_districts", force: :cascade do |t|
    t.string   "name",       null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_index "school_district_districts", ["name"], name: "index_school_district_districts_on_name", unique: true, using: :btree

  create_table "school_district_schools", force: :cascade do |t|
    t.string   "name",                        null: false
    t.integer  "school_district_district_id"
    t.datetime "created_at",                  null: false
    t.datetime "updated_at",                  null: false
  end

  add_index "school_district_schools", ["name", "school_district_district_id"], name: "index_schools_on_name_and_district_id", unique: true, using: :btree
  add_index "school_district_schools", ["name"], name: "index_school_district_schools_on_name", unique: true, where: "(school_district_district_id IS NULL)", using: :btree
  add_index "school_district_schools", ["school_district_district_id"], name: "index_school_district_schools_on_school_district_district_id", using: :btree

  create_table "settings", force: :cascade do |t|
    t.string   "var",                   null: false
    t.text     "value"
    t.integer  "thing_id"
    t.string   "thing_type", limit: 30
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "settings", ["thing_type", "thing_id", "var"], name: "index_settings_on_thing_type_and_thing_id_and_var", unique: true, using: :btree

  create_table "short_code_short_codes", force: :cascade do |t|
    t.string   "code",       null: false
    t.text     "uri",        null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_index "short_code_short_codes", ["code"], name: "index_short_code_short_codes_on_code", unique: true, using: :btree

  create_table "tasks_assistants", force: :cascade do |t|
    t.string   "name",            null: false
    t.string   "code_class_name", null: false
    t.datetime "created_at",      null: false
    t.datetime "updated_at",      null: false
  end

  add_index "tasks_assistants", ["code_class_name"], name: "index_tasks_assistants_on_code_class_name", unique: true, using: :btree
  add_index "tasks_assistants", ["name"], name: "index_tasks_assistants_on_name", unique: true, using: :btree

  create_table "tasks_concept_coach_tasks", force: :cascade do |t|
    t.integer  "content_page_id", null: false
    t.datetime "created_at",      null: false
    t.datetime "updated_at",      null: false
    t.integer  "entity_role_id",  null: false
    t.integer  "tasks_task_id",   null: false
  end

  add_index "tasks_concept_coach_tasks", ["content_page_id"], name: "index_tasks_concept_coach_tasks_on_content_page_id", using: :btree
  add_index "tasks_concept_coach_tasks", ["entity_role_id", "content_page_id"], name: "index_tasks_concept_coach_tasks_on_e_r_id_and_c_p_id", unique: true, using: :btree
  add_index "tasks_concept_coach_tasks", ["tasks_task_id"], name: "index_tasks_concept_coach_tasks_on_tasks_task_id", unique: true, using: :btree

  create_table "tasks_course_assistants", force: :cascade do |t|
    t.integer  "course_profile_course_id",                null: false
    t.integer  "tasks_assistant_id",                      null: false
    t.string   "tasks_task_plan_type",                    null: false
    t.datetime "created_at",                              null: false
    t.datetime "updated_at",                              null: false
    t.text     "settings",                 default: "{}", null: false
    t.text     "data",                     default: "{}", null: false
  end

  add_index "tasks_course_assistants", ["course_profile_course_id", "tasks_task_plan_type"], name: "index_tasks_course_assistants_on_course_id_and_task_plan_type", unique: true, using: :btree
  add_index "tasks_course_assistants", ["tasks_assistant_id", "course_profile_course_id"], name: "index_tasks_course_assistants_on_assistant_id_and_course_id", using: :btree

  create_table "tasks_performance_report_exports", force: :cascade do |t|
    t.integer  "course_profile_course_id", null: false
    t.integer  "entity_role_id",           null: false
    t.string   "export"
    t.datetime "created_at",               null: false
    t.datetime "updated_at",               null: false
  end

  add_index "tasks_performance_report_exports", ["course_profile_course_id"], name: "index_t_performance_report_exports_on_c_p_course_id", using: :btree
  add_index "tasks_performance_report_exports", ["entity_role_id", "course_profile_course_id"], name: "index_performance_report_exports_on_role_and_course", using: :btree

  create_table "tasks_period_caches", force: :cascade do |t|
    t.integer  "course_membership_period_id",                null: false
    t.integer  "content_ecosystem_id",                       null: false
    t.integer  "tasks_task_plan_id"
    t.datetime "opens_at"
    t.datetime "due_at"
    t.integer  "student_ids",                                null: false, array: true
    t.text     "as_toc",                      default: "{}", null: false
    t.datetime "created_at",                                 null: false
    t.datetime "updated_at",                                 null: false
  end

  add_index "tasks_period_caches", ["content_ecosystem_id"], name: "index_tasks_period_caches_on_content_ecosystem_id", using: :btree
  add_index "tasks_period_caches", ["course_membership_period_id", "content_ecosystem_id", "tasks_task_plan_id"], name: "index_period_caches_on_c_m_p_id_and_c_e_id_and_t_t_p_id", unique: true, using: :btree
  add_index "tasks_period_caches", ["course_membership_period_id", "content_ecosystem_id"], name: "index_period_caches_on_c_m_p_id_and_c_e_id", unique: true, where: "(tasks_task_plan_id IS NULL)", using: :btree
  add_index "tasks_period_caches", ["course_membership_period_id"], name: "index_tasks_period_caches_on_course_membership_period_id", using: :btree
  add_index "tasks_period_caches", ["due_at"], name: "index_tasks_period_caches_on_due_at", using: :btree
  add_index "tasks_period_caches", ["opens_at"], name: "index_tasks_period_caches_on_opens_at", using: :btree
  add_index "tasks_period_caches", ["student_ids"], name: "index_tasks_period_caches_on_student_ids", using: :gin
  add_index "tasks_period_caches", ["tasks_task_plan_id"], name: "index_tasks_period_caches_on_tasks_task_plan_id", using: :btree

  create_table "tasks_task_caches", force: :cascade do |t|
    t.integer  "tasks_task_id",                       null: false
    t.integer  "content_ecosystem_id",                null: false
    t.integer  "task_type",                           null: false
    t.datetime "opens_at"
    t.datetime "due_at"
    t.datetime "feedback_at"
    t.integer  "student_ids",                         null: false, array: true
    t.string   "student_names",                       null: false, array: true
    t.text     "as_toc",               default: "{}", null: false
    t.datetime "created_at",                          null: false
    t.datetime "updated_at",                          null: false
    t.boolean  "is_cached_for_period",                null: false
  end

  add_index "tasks_task_caches", ["content_ecosystem_id"], name: "index_tasks_task_caches_on_content_ecosystem_id", using: :btree
  add_index "tasks_task_caches", ["due_at"], name: "index_tasks_task_caches_on_due_at", using: :btree
  add_index "tasks_task_caches", ["feedback_at"], name: "index_tasks_task_caches_on_feedback_at", using: :btree
  add_index "tasks_task_caches", ["is_cached_for_period"], name: "index_tasks_task_caches_on_is_cached_for_period", using: :btree
  add_index "tasks_task_caches", ["opens_at"], name: "index_tasks_task_caches_on_opens_at", using: :btree
  add_index "tasks_task_caches", ["student_ids"], name: "index_tasks_task_caches_on_student_ids", using: :gin
  add_index "tasks_task_caches", ["task_type"], name: "index_tasks_task_caches_on_task_type", using: :btree
  add_index "tasks_task_caches", ["tasks_task_id", "content_ecosystem_id"], name: "index_task_caches_on_task_id_and_ecosystem_id", unique: true, using: :btree

  create_table "tasks_task_plans", force: :cascade do |t|
    t.integer  "tasks_assistant_id",                        null: false
    t.integer  "owner_id",                                  null: false
    t.string   "owner_type",                                null: false
    t.string   "type",                                      null: false
    t.string   "title",                                     null: false
    t.text     "description"
    t.text     "settings",                                  null: false
    t.datetime "publish_last_requested_at"
    t.datetime "first_published_at"
    t.string   "publish_job_uuid"
    t.datetime "created_at",                                null: false
    t.datetime "updated_at",                                null: false
    t.integer  "content_ecosystem_id",                      null: false
    t.boolean  "is_feedback_immediate",     default: true,  null: false
    t.datetime "withdrawn_at"
    t.datetime "last_published_at"
    t.integer  "cloned_from_id"
    t.boolean  "is_preview",                default: false
  end

  add_index "tasks_task_plans", ["cloned_from_id"], name: "index_tasks_task_plans_on_cloned_from_id", using: :btree
  add_index "tasks_task_plans", ["content_ecosystem_id"], name: "index_tasks_task_plans_on_content_ecosystem_id", using: :btree
  add_index "tasks_task_plans", ["owner_id", "owner_type"], name: "index_tasks_task_plans_on_owner_id_and_owner_type", using: :btree
  add_index "tasks_task_plans", ["tasks_assistant_id"], name: "index_tasks_task_plans_on_tasks_assistant_id", using: :btree
  add_index "tasks_task_plans", ["withdrawn_at"], name: "index_tasks_task_plans_on_withdrawn_at", using: :btree

  create_table "tasks_task_steps", force: :cascade do |t|
    t.integer  "tasks_task_id",                       null: false
    t.integer  "tasked_id",                           null: false
    t.string   "tasked_type",                         null: false
    t.integer  "number",                              null: false
    t.datetime "first_completed_at"
    t.datetime "last_completed_at"
    t.integer  "group_type",           default: 0,    null: false
    t.datetime "created_at",                          null: false
    t.datetime "updated_at",                          null: false
    t.text     "related_exercise_ids", default: "[]", null: false
    t.text     "labels",               default: "[]", null: false
    t.text     "spy",                  default: "{}", null: false
    t.integer  "content_page_id"
    t.integer  "fragment_index"
  end

  add_index "tasks_task_steps", ["first_completed_at"], name: "index_tasks_task_steps_on_first_completed_at", using: :btree
  add_index "tasks_task_steps", ["last_completed_at"], name: "index_tasks_task_steps_on_last_completed_at", using: :btree
  add_index "tasks_task_steps", ["tasked_id", "tasked_type"], name: "index_tasks_task_steps_on_tasked_id_and_tasked_type", unique: true, using: :btree
  add_index "tasks_task_steps", ["tasks_task_id", "number"], name: "index_tasks_task_steps_on_tasks_task_id_and_number", unique: true, using: :btree

  create_table "tasks_tasked_exercises", force: :cascade do |t|
    t.integer  "content_exercise_id",                               null: false
    t.string   "url",                                               null: false
    t.text     "content",                                           null: false
    t.string   "title"
    t.text     "free_response"
    t.string   "answer_id"
    t.datetime "created_at",                                        null: false
    t.datetime "updated_at",                                        null: false
    t.string   "correct_answer_id",                                 null: false
    t.boolean  "is_in_multipart",     default: false,               null: false
    t.string   "question_id",                                       null: false
    t.text     "context"
    t.uuid     "uuid",                default: "gen_random_uuid()"
    t.integer  "question_index",                                    null: false
  end

  add_index "tasks_tasked_exercises", ["content_exercise_id"], name: "index_tasks_tasked_exercises_on_content_exercise_id", using: :btree
  add_index "tasks_tasked_exercises", ["question_id"], name: "index_tasks_tasked_exercises_on_question_id", using: :btree
  add_index "tasks_tasked_exercises", ["uuid"], name: "index_tasks_tasked_exercises_on_uuid", unique: true, using: :btree

  create_table "tasks_tasked_external_urls", force: :cascade do |t|
    t.string   "url",        null: false
    t.string   "title"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "tasks_tasked_interactives", force: :cascade do |t|
    t.string   "url",        null: false
    t.text     "content",    null: false
    t.string   "title"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "tasks_tasked_placeholders", force: :cascade do |t|
    t.integer  "placeholder_type", default: 0, null: false
    t.datetime "created_at",                   null: false
    t.datetime "updated_at",                   null: false
  end

  create_table "tasks_tasked_readings", force: :cascade do |t|
    t.string   "url",                          null: false
    t.text     "content",                      null: false
    t.string   "title"
    t.datetime "created_at",                   null: false
    t.datetime "updated_at",                   null: false
    t.text     "book_location", default: "[]", null: false
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
    t.datetime "opens_at_ntz",       null: false
    t.datetime "due_at_ntz",         null: false
    t.datetime "created_at",         null: false
    t.datetime "updated_at",         null: false
    t.integer  "time_zone_id",       null: false
  end

  add_index "tasks_tasking_plans", ["due_at_ntz", "opens_at_ntz"], name: "index_tasks_tasking_plans_on_due_at_ntz_and_opens_at_ntz", using: :btree
  add_index "tasks_tasking_plans", ["opens_at_ntz"], name: "index_tasks_tasking_plans_on_opens_at_ntz", using: :btree
  add_index "tasks_tasking_plans", ["target_id", "target_type", "tasks_task_plan_id"], name: "index_tasking_plans_on_t_id_and_t_type_and_t_p_id", unique: true, using: :btree
  add_index "tasks_tasking_plans", ["tasks_task_plan_id"], name: "index_tasks_tasking_plans_on_tasks_task_plan_id", using: :btree
  add_index "tasks_tasking_plans", ["time_zone_id"], name: "index_tasks_tasking_plans_on_time_zone_id", using: :btree

  create_table "tasks_taskings", force: :cascade do |t|
    t.integer  "entity_role_id",              null: false
    t.integer  "course_membership_period_id"
    t.datetime "created_at",                  null: false
    t.datetime "updated_at",                  null: false
    t.integer  "tasks_task_id",               null: false
  end

  add_index "tasks_taskings", ["course_membership_period_id"], name: "index_tasks_taskings_on_course_membership_period_id", using: :btree
  add_index "tasks_taskings", ["entity_role_id"], name: "index_tasks_taskings_on_entity_role_id", using: :btree
  add_index "tasks_taskings", ["tasks_task_id", "entity_role_id"], name: "index_tasks_taskings_on_tasks_task_id_and_entity_role_id", unique: true, using: :btree

  create_table "tasks_tasks", force: :cascade do |t|
    t.integer  "tasks_task_plan_id"
    t.integer  "task_type",                                                                  null: false
    t.string   "title",                                                                      null: false
    t.text     "description"
    t.datetime "opens_at_ntz"
    t.datetime "due_at_ntz"
    t.datetime "feedback_at_ntz"
    t.datetime "last_worked_at"
    t.integer  "steps_count",                                  default: 0,                   null: false
    t.integer  "completed_steps_count",                        default: 0,                   null: false
    t.integer  "core_steps_count",                             default: 0,                   null: false
    t.integer  "completed_core_steps_count",                   default: 0,                   null: false
    t.integer  "exercise_steps_count",                         default: 0,                   null: false
    t.integer  "completed_exercise_steps_count",               default: 0,                   null: false
    t.integer  "recovered_exercise_steps_count",               default: 0,                   null: false
    t.integer  "correct_exercise_steps_count",                 default: 0,                   null: false
    t.integer  "placeholder_steps_count",                      default: 0,                   null: false
    t.integer  "placeholder_exercise_steps_count",             default: 0,                   null: false
    t.datetime "created_at",                                                                 null: false
    t.datetime "updated_at",                                                                 null: false
    t.integer  "correct_on_time_exercise_steps_count",         default: 0,                   null: false
    t.integer  "completed_on_time_exercise_steps_count",       default: 0,                   null: false
    t.integer  "completed_on_time_steps_count",                default: 0,                   null: false
    t.datetime "accepted_late_at"
    t.integer  "correct_accepted_late_exercise_steps_count",   default: 0,                   null: false
    t.integer  "completed_accepted_late_exercise_steps_count", default: 0,                   null: false
    t.integer  "completed_accepted_late_steps_count",          default: 0,                   null: false
    t.integer  "time_zone_id"
    t.datetime "hidden_at"
    t.text     "spy",                                          default: "{}",                null: false
    t.uuid     "uuid",                                         default: "gen_random_uuid()"
    t.integer  "content_ecosystem_id",                                                       null: false
    t.boolean  "spes_are_assigned",                            default: false,               null: false
    t.boolean  "pes_are_assigned",                             default: false,               null: false
  end

  add_index "tasks_tasks", ["content_ecosystem_id"], name: "index_tasks_tasks_on_content_ecosystem_id", using: :btree
  add_index "tasks_tasks", ["due_at_ntz", "opens_at_ntz"], name: "index_tasks_tasks_on_due_at_ntz_and_opens_at_ntz", using: :btree
  add_index "tasks_tasks", ["hidden_at"], name: "index_tasks_tasks_on_hidden_at", using: :btree
  add_index "tasks_tasks", ["last_worked_at"], name: "index_tasks_tasks_on_last_worked_at", using: :btree
  add_index "tasks_tasks", ["opens_at_ntz"], name: "index_tasks_tasks_on_opens_at_ntz", using: :btree
  add_index "tasks_tasks", ["task_type", "created_at"], name: "index_tasks_tasks_on_task_type_and_created_at", using: :btree
  add_index "tasks_tasks", ["tasks_task_plan_id"], name: "index_tasks_tasks_on_tasks_task_plan_id", using: :btree
  add_index "tasks_tasks", ["time_zone_id"], name: "index_tasks_tasks_on_time_zone_id", using: :btree
  add_index "tasks_tasks", ["uuid"], name: "index_tasks_tasks_on_uuid", unique: true, using: :btree

  create_table "time_zones", force: :cascade do |t|
    t.string   "name",       null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_index "time_zones", ["name"], name: "index_time_zones_on_name", using: :btree

  create_table "user_administrators", force: :cascade do |t|
    t.integer  "user_profile_id", null: false
    t.datetime "created_at",      null: false
    t.datetime "updated_at",      null: false
  end

  add_index "user_administrators", ["user_profile_id"], name: "index_user_administrators_on_user_profile_id", unique: true, using: :btree

  create_table "user_content_analysts", force: :cascade do |t|
    t.integer  "user_profile_id", null: false
    t.datetime "created_at",      null: false
    t.datetime "updated_at",      null: false
  end

  add_index "user_content_analysts", ["user_profile_id"], name: "index_user_content_analysts_on_user_profile_id", unique: true, using: :btree

  create_table "user_customer_services", force: :cascade do |t|
    t.integer  "user_profile_id", null: false
    t.datetime "created_at",      null: false
    t.datetime "updated_at",      null: false
  end

  add_index "user_customer_services", ["user_profile_id"], name: "index_user_customer_services_on_user_profile_id", unique: true, using: :btree

  create_table "user_profiles", force: :cascade do |t|
    t.integer  "account_id",  null: false
    t.datetime "created_at",  null: false
    t.datetime "updated_at",  null: false
    t.text     "ui_settings"
  end

  add_index "user_profiles", ["account_id"], name: "index_user_profiles_on_account_id", unique: true, using: :btree

  create_table "user_researchers", force: :cascade do |t|
    t.integer  "user_profile_id", null: false
    t.datetime "created_at",      null: false
    t.datetime "updated_at",      null: false
  end

  add_index "user_researchers", ["user_profile_id"], name: "index_user_researchers_on_user_profile_id", unique: true, using: :btree

  create_table "user_tour_views", force: :cascade do |t|
    t.integer "view_count",      default: 0, null: false
    t.integer "user_profile_id",             null: false
    t.integer "user_tour_id",                null: false
  end

  add_index "user_tour_views", ["user_profile_id", "user_tour_id"], name: "index_user_tour_views_on_user_profile_id_and_user_tour_id", unique: true, using: :btree
  add_index "user_tour_views", ["user_tour_id"], name: "index_user_tour_views_on_user_tour_id", using: :btree

  create_table "user_tours", force: :cascade do |t|
    t.text     "identifier", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_index "user_tours", ["identifier"], name: "index_user_tours_on_identifier", unique: true, using: :btree

  add_foreign_key "catalog_offerings", "content_ecosystems", on_update: :cascade, on_delete: :nullify
  add_foreign_key "content_books", "content_ecosystems", on_update: :cascade, on_delete: :cascade
  add_foreign_key "content_chapters", "content_books", on_update: :cascade, on_delete: :cascade
  add_foreign_key "content_chapters", "content_pools", column: "content_all_exercises_pool_id", on_update: :cascade, on_delete: :nullify
  add_foreign_key "content_exercise_tags", "content_exercises", on_update: :cascade, on_delete: :cascade
  add_foreign_key "content_exercise_tags", "content_tags", on_update: :cascade, on_delete: :cascade
  add_foreign_key "content_exercises", "content_pages", on_update: :cascade, on_delete: :cascade
  add_foreign_key "content_lo_teks_tags", "content_tags", column: "lo_id", on_update: :cascade, on_delete: :cascade
  add_foreign_key "content_lo_teks_tags", "content_tags", column: "teks_id", on_update: :cascade, on_delete: :cascade
  add_foreign_key "content_maps", "content_ecosystems", column: "content_from_ecosystem_id", on_update: :cascade, on_delete: :cascade
  add_foreign_key "content_maps", "content_ecosystems", column: "content_to_ecosystem_id", on_update: :cascade, on_delete: :cascade
  add_foreign_key "content_page_tags", "content_pages", on_update: :cascade, on_delete: :cascade
  add_foreign_key "content_page_tags", "content_tags", on_update: :cascade, on_delete: :cascade
  add_foreign_key "content_pages", "content_chapters", on_update: :cascade, on_delete: :cascade
  add_foreign_key "content_pages", "content_pools", column: "content_all_exercises_pool_id", on_update: :cascade, on_delete: :nullify
  add_foreign_key "content_pages", "content_pools", column: "content_homework_core_pool_id", on_update: :cascade, on_delete: :nullify
  add_foreign_key "content_pages", "content_pools", column: "content_homework_dynamic_pool_id", on_update: :cascade, on_delete: :nullify
  add_foreign_key "content_pages", "content_pools", column: "content_practice_widget_pool_id", on_update: :cascade, on_delete: :nullify
  add_foreign_key "content_pages", "content_pools", column: "content_reading_context_pool_id", on_update: :cascade, on_delete: :nullify
  add_foreign_key "content_pages", "content_pools", column: "content_reading_dynamic_pool_id", on_update: :cascade, on_delete: :nullify
  add_foreign_key "content_pools", "content_ecosystems", on_update: :cascade, on_delete: :cascade
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
  add_foreign_key "course_membership_teachers", "course_profile_courses", on_update: :cascade, on_delete: :cascade
  add_foreign_key "course_membership_teachers", "entity_roles", on_update: :cascade, on_delete: :cascade
  add_foreign_key "course_profile_courses", "catalog_offerings", on_update: :cascade, on_delete: :nullify
  add_foreign_key "course_profile_courses", "course_profile_courses", column: "cloned_from_id", on_update: :cascade, on_delete: :nullify
  add_foreign_key "course_profile_courses", "school_district_schools", on_update: :cascade, on_delete: :nullify
  add_foreign_key "course_profile_courses", "time_zones", on_update: :cascade
  add_foreign_key "lms_contexts", "course_profile_courses", on_update: :cascade, on_delete: :cascade
  add_foreign_key "lms_contexts", "lms_tool_consumers", on_update: :cascade, on_delete: :cascade
  add_foreign_key "lms_course_score_callbacks", "course_profile_courses", on_update: :cascade, on_delete: :cascade
  add_foreign_key "lms_course_score_callbacks", "user_profiles", on_update: :cascade, on_delete: :cascade
  add_foreign_key "lms_nonces", "lms_apps", on_update: :cascade, on_delete: :cascade
  add_foreign_key "oauth_access_grants", "oauth_applications", column: "application_id"
  add_foreign_key "oauth_access_tokens", "oauth_applications", column: "application_id"
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
  add_foreign_key "role_role_users", "entity_roles", on_update: :cascade, on_delete: :cascade
  add_foreign_key "role_role_users", "user_profiles", on_update: :cascade, on_delete: :cascade
  add_foreign_key "school_district_schools", "school_district_districts", on_update: :cascade, on_delete: :nullify
  add_foreign_key "tasks_concept_coach_tasks", "content_pages", on_update: :cascade, on_delete: :cascade
  add_foreign_key "tasks_concept_coach_tasks", "entity_roles", on_update: :cascade, on_delete: :cascade
  add_foreign_key "tasks_concept_coach_tasks", "tasks_tasks", on_update: :cascade, on_delete: :cascade
  add_foreign_key "tasks_course_assistants", "course_profile_courses", on_update: :cascade, on_delete: :cascade
  add_foreign_key "tasks_course_assistants", "tasks_assistants", on_update: :cascade, on_delete: :cascade
  add_foreign_key "tasks_performance_report_exports", "course_profile_courses", on_update: :cascade, on_delete: :cascade
  add_foreign_key "tasks_performance_report_exports", "entity_roles", on_update: :cascade, on_delete: :cascade
  add_foreign_key "tasks_period_caches", "content_ecosystems", on_update: :cascade, on_delete: :cascade
  add_foreign_key "tasks_period_caches", "course_membership_periods", on_update: :cascade, on_delete: :cascade
  add_foreign_key "tasks_period_caches", "tasks_task_plans", on_update: :cascade, on_delete: :cascade
  add_foreign_key "tasks_task_caches", "content_ecosystems", on_update: :cascade, on_delete: :cascade
  add_foreign_key "tasks_task_caches", "tasks_tasks", on_update: :cascade, on_delete: :cascade
  add_foreign_key "tasks_task_plans", "content_ecosystems", on_update: :cascade, on_delete: :cascade
  add_foreign_key "tasks_task_plans", "tasks_assistants", on_update: :cascade, on_delete: :cascade
  add_foreign_key "tasks_task_plans", "tasks_task_plans", column: "cloned_from_id", on_update: :cascade, on_delete: :nullify
  add_foreign_key "tasks_task_steps", "tasks_tasks", on_update: :cascade, on_delete: :cascade
  add_foreign_key "tasks_tasked_exercises", "content_exercises", on_update: :cascade, on_delete: :cascade
  add_foreign_key "tasks_tasking_plans", "tasks_task_plans", on_update: :cascade, on_delete: :cascade
  add_foreign_key "tasks_tasking_plans", "time_zones", on_update: :cascade
  add_foreign_key "tasks_taskings", "course_membership_periods", on_update: :cascade, on_delete: :nullify
  add_foreign_key "tasks_taskings", "entity_roles", on_update: :cascade, on_delete: :cascade
  add_foreign_key "tasks_taskings", "tasks_tasks", on_update: :cascade, on_delete: :cascade
  add_foreign_key "tasks_tasks", "content_ecosystems", on_update: :cascade, on_delete: :cascade
  add_foreign_key "tasks_tasks", "tasks_task_plans", on_update: :cascade, on_delete: :cascade
  add_foreign_key "tasks_tasks", "time_zones", on_update: :cascade, on_delete: :nullify
  add_foreign_key "user_administrators", "user_profiles", on_update: :cascade, on_delete: :cascade
  add_foreign_key "user_content_analysts", "user_profiles", on_update: :cascade, on_delete: :cascade
  add_foreign_key "user_customer_services", "user_profiles", on_update: :cascade, on_delete: :cascade
  add_foreign_key "user_profiles", "openstax_accounts_accounts", column: "account_id", on_update: :cascade, on_delete: :cascade
  add_foreign_key "user_researchers", "user_profiles", on_update: :cascade, on_delete: :cascade
  add_foreign_key "user_tour_views", "user_profiles"
  add_foreign_key "user_tour_views", "user_tours"

  create_view "cc_page_stats", materialized: true,  sql_definition: <<-SQL
      SELECT content_exercises.content_page_id AS coach_task_content_page_id,
      course_membership_periods.course_profile_course_id AS course_id,
      course_membership_periods.id AS course_period_id,
      tasks_task_steps.group_type,
      count(tasks_task_steps.*) AS steps_count,
      max(tasks_task_steps.last_completed_at) AS task_steps_last_completed_at,
      count(tasks_task_steps.first_completed_at) AS completed_count,
      count(tasks_task_steps.first_completed_at) FILTER (WHERE ((tasks_tasked_exercises.answer_id)::text = (tasks_tasked_exercises.correct_answer_id)::text)) AS correct_count,
      array_agg(DISTINCT tasks_taskings.entity_role_id) AS role_ids,
      array_agg(DISTINCT tasks_tasks.id) AS task_ids
     FROM (((((content_exercises
       JOIN tasks_tasked_exercises ON ((tasks_tasked_exercises.content_exercise_id = content_exercises.id)))
       JOIN tasks_task_steps ON (((tasks_task_steps.tasked_id = tasks_tasked_exercises.id) AND ((tasks_task_steps.tasked_type)::text = 'Tasks::Models::TaskedExercise'::text))))
       JOIN tasks_tasks ON (((tasks_tasks.id = tasks_task_steps.tasks_task_id) AND (tasks_tasks.hidden_at IS NULL) AND (tasks_tasks.completed_exercise_steps_count > 0))))
       JOIN tasks_taskings ON ((tasks_taskings.tasks_task_id = tasks_tasks.id)))
       JOIN course_membership_periods ON (((course_membership_periods.id = tasks_taskings.course_membership_period_id) AND (course_membership_periods.archived_at IS NULL))))
    GROUP BY course_membership_periods.course_profile_course_id, course_membership_periods.id, content_exercises.content_page_id, tasks_task_steps.group_type;
  SQL

  add_index "cc_page_stats", ["course_period_id", "coach_task_content_page_id", "group_type"], name: "cc_page_stats_uniq", unique: true, using: :btree

end
