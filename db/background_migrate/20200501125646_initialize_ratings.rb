class InitializeRatings < ActiveRecord::Migration[5.2]
  def up
    current_time = Time.current

    Entity::Role.preload(
      taskings: {
        task: [ :course, :task_steps, task_plan: [ :course, :grading_template, :extensions ] ]
      }, student: :period
    ).find_each do |role|
      role.taskings.map(&:task).each do |task|
        feedback_available = task.auto_grading_feedback_available?
        feedback_at = [ task.due_at, current_time ].max unless feedback_available

        page_uuids_book_part_uuids = Content::Models::Page.where(
          id: task.task_steps.map(&:content_page_id)
        ).distinct.pluck(:uuid, :parent_book_part_uuid)

        page_uuids_book_part_uuids.map(&:first).uniq.each do |page_uuid|
          Ratings::UpdateRoleBookPart.set(queue: 'maintenance').perform_later(
            role: role, book_part_uuid: page_uuid, is_page: true
          )

          Ratings::UpdateRoleBookPart.set(queue: 'maintenance', run_at: feedback_at).perform_later(
            role: role, book_part_uuid: page_uuid, is_page: true
          ) unless feedback_available

          Ratings::UpdatePeriodBookPart.set(queue: 'maintenance').perform_later(
            period: role.student.period, book_part_uuid: page_uuid, is_page: true
          ) if role.student?
        end

        page_uuids_book_part_uuids.map(&:second).uniq.each do |book_part_uuid|
          Ratings::UpdateRoleBookPart.set(queue: 'maintenance').perform_later(
            role: role, book_part_uuid: book_part_uuid, is_page: false
          )

          Ratings::UpdateRoleBookPart.set(queue: 'maintenance', run_at: feedback_at).perform_later(
            role: role, book_part_uuid: book_part_uuid, is_page: false
          ) unless feedback_available

          Ratings::UpdatePeriodBookPart.set(queue: 'maintenance').perform_later(
            period: role.student.period, book_part_uuid: book_part_uuid, is_page: false
          ) if role.student?
        end
      end
    end
  end

  def down
  end
end
