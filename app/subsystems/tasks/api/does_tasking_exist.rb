class Tasks::Api::DoesTaskingExist
  lev_routine

  protected

  def exec(task:, roles:)
    raise NotYetImplemented unless task.is_a?(::Task)

    role_ids = roles.collect{|r| r.id}

    outputs[:does_tasking_exist] = 
      Entity::Task.joins{taskings}
                  .joins{legacy_task_maps}
                  .where{legacy_task_maps.task_id == my{task.id}}
                  .where{taskings.entity_role_id.in role_ids}.any?
  end
end