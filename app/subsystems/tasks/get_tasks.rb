require_relative 'models/entity_extensions'

class Tasks::GetTasks
  lev_routine express_output: :tasks

  protected

  def exec(roles:)
    role_ids = as_id_array(roles)

    outputs[:tasks] = 
      Entity::Models::Task.joins{taskings}
                          .where{taskings.entity_role_id.in role_ids}
  end

  def as_id_array(values)
    return [] if values.blank?
    
    values = [values].flatten.compact
    
    values.first.is_a?(Integer) ?
      values : 
      values.collect{|v| v.id}
  end
end
