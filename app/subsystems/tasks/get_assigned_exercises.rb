class Tasks::GetAssignedExercises
  lev_routine outputs: { exercises: :_self }

  include VerifyAndGetIdArray

  protected

  def exec(roles:, relation: Content::Models::Exercise.all)
    role_ids = verify_and_get_id_array(roles, Entity::Role)

    set(exercises: relation.joins(
                     tasked_exercises: {
                       task_step: {
                         task: :taskings
                       }
                     }
                   ).where(
                     tasked_exercises: {
                       task_step: {
                         task: {
                           taskings: {
                             entity_role_id: role_ids
                           }
                         }
                       }
                     }
                   ))
  end

end
