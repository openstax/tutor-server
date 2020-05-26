class CreateTasksGradingTemplates < ActiveRecord::Migration[5.2]
  def up
    create_table :tasks_grading_templates do |t|
      t.references :course_profile_course,          null: false, index: false
      t.integer    :task_plan_type,                 null: false
      t.string     :name,                           null: false
      t.float      :completion_weight,              precision: 3, scale: 2, null: false
      t.float      :correctness_weight,             precision: 3, scale: 2, null: false
      t.integer    :auto_grading_feedback_on,       null: false
      t.integer    :manual_grading_feedback_on,     null: false
      t.float      :late_work_immediate_penalty,    precision: 3, scale: 2, null: false
      t.float      :late_work_per_day_penalty,      precision: 3, scale: 2, null: false
      t.string     :default_open_time,              null: false
      t.string     :default_due_time,               null: false
      t.integer    :default_due_date_offset_days,   null: false
      t.integer    :default_close_date_offset_days, null: false
      t.datetime   :deleted_at

      t.timestamps
    end

    add_column :course_profile_courses, :homework_weight, :float,
               precision: 3, scale: 2, default: 0.5, null: false
    add_column :course_profile_courses, :reading_weight, :float,
               precision: 3, scale: 2, default: 0.5, null: false

    add_column :tasks_task_plans, :tasks_grading_template_id, :integer

    add_column :tasks_task_caches, :auto_grading_feedback_on, :integer
    add_column :tasks_task_caches, :manual_grading_feedback_on, :integer

    CourseProfile::Models::Course.reset_column_information
    Tasks::Models::TaskPlan.reset_column_information
    CourseProfile::Models::Course.find_each do |course|
      course.homework_weight = course.homework_progress_weight + course.homework_score_weight
      course.reading_weight = course.reading_progress_weight + course.reading_score_weight
      reading_completion_weight = course.reading_weight == 0 ?
                                  0.9 : course.reading_progress_weight/course.reading_weight
      reading_correctness_weight = course.reading_weight == 0 ?
                                     0.1 : course.reading_score_weight/course.reading_weight

      course.save validate: false

      tps_by_is_feedback_immediate = Tasks::Models::TaskPlan.select(:id, :is_feedback_immediate)
                                                            .where(owner: course, type: 'homework')
                                                            .group(&:is_feedback_immediate)

      if tps_by_is_feedback_immediate.size == 0
        homework_template = Tasks::Models::GradingTemplate.new(
          course: course,
          task_plan_type: :homework,
          name: 'OpenStax Homework',
          completion_weight: 0.0,
          correctness_weight: 1.0,
          auto_grading_feedback_on: :answer,
          manual_grading_feedback_on: :publish,
          late_work_immediate_penalty: 0.0,
          late_work_per_day_penalty: 0.1,
          default_open_time: course.default_open_time || '00:01',
          default_due_time: course.default_due_time || '07:00',
          default_due_date_offset_days: 7,
          default_close_date_offset_days: 7
        )
        homework_template.save validate: false
      else
        use_different_names = tps_by_is_feedback_immediate.size > 1
        tps_by_is_feedback_immediate.each do |is_feedback_immediate, tps|
          name_suffix = if use_different_names
            is_feedback_immediate ? ', immediate feedback' : ', feedback after due date'
          else
            ''
          end
          homework_template = Tasks::Models::GradingTemplate.new(
            course: course,
            task_plan_type: :homework,
            name: "OpenStax Homework#{name_suffix}",
            completion_weight: 0.0,
            correctness_weight: 1.0,
            auto_grading_feedback_on: is_feedback_immediate ? :answer : :due,
            manual_grading_feedback_on: :publish,
            late_work_immediate_penalty: 0.0,
            late_work_per_day_penalty: 0.1,
            default_open_time: course.default_open_time || '00:01',
            default_due_time: course.default_due_time || '07:00',
            default_due_date_offset_days: 7,
            default_close_date_offset_days: 7
          )
          homework_template.save validate: false

          Tasks::Models::TaskPlan.where(id: tps.map(&:id)).update_all(
            tasks_grading_template_id: homework_template.id
          )
        end
      end

      reading_template = Tasks::Models::GradingTemplate.new(
        course: course,
        task_plan_type: :reading,
        name: 'OpenStax Reading',
        completion_weight: reading_completion_weight,
        correctness_weight: reading_correctness_weight,
        auto_grading_feedback_on: :answer,
        manual_grading_feedback_on: :grade,
        late_work_immediate_penalty: 0.0,
        late_work_per_day_penalty: 0.1,
        default_open_time: course.default_open_time || '00:01',
        default_due_time: course.default_due_time || '07:00',
        default_due_date_offset_days: 7,
        default_close_date_offset_days: 7
      )
      reading_template.save validate: false

      Tasks::Models::TaskPlan.where(
        owner: course, type: 'reading'
      ).update_all(tasks_grading_template_id: reading_template.id)
    end

    Tasks::Models::TaskCache.reset_column_information
    Tasks::Models::TaskCache.where.not(feedback_at: nil).update_all(auto_grading_feedback_on: :due)
    Tasks::Models::TaskCache.where(feedback_at: nil).update_all(auto_grading_feedback_on: :answer)
    Tasks::Models::TaskCache.update_all(manual_grading_feedback_on: :grade)

    change_column_null :tasks_task_caches, :auto_grading_feedback_on, false
    change_column_null :tasks_task_caches, :manual_grading_feedback_on, false

    add_index :tasks_grading_templates, [ :course_profile_course_id, :task_plan_type, :deleted_at ],
              name: 'index_tasks_grading_templates_on_course_type_and_deleted'

    add_index :tasks_task_plans, :tasks_grading_template_id

    add_foreign_key :tasks_task_plans, :tasks_grading_templates,
                    on_update: :cascade, on_delete: :restrict

    remove_column :tasks_task_plans, :is_feedback_immediate, :boolean, default: true, null: false

    remove_column :tasks_tasks, :feedback_at_ntz, :datetime

    remove_column :tasks_task_caches, :feedback_at, :datetime

    remove_column :course_profile_courses, :homework_progress_weight, :float,
                  precision: 3, scale: 2, default: 0, null: false
    remove_column :course_profile_courses, :homework_score_weight, :float,
                  precision: 3, scale: 2, default: 1, null: false
    remove_column :course_profile_courses, :reading_progress_weight, :float,
                  precision: 3, scale: 2, default: 0, null: false
    remove_column :course_profile_courses, :reading_score_weight, :float,
                  precision: 3, scale: 2, default: 0, null: false

    remove_column :course_profile_courses, :default_open_time, :string
    remove_column :course_profile_courses, :default_due_time, :string

    remove_column :course_membership_periods, :default_open_time, :string
    remove_column :course_membership_periods, :default_due_time, :string
  end

  def down
    # We can make this reversible if needed, but it may not be worth the effort
    raise ActiveRecord::IrreversibleMigration
  end
end
