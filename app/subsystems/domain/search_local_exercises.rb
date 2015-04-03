class Domain::SearchLocalExercises

  lev_routine express_output: :items

  uses_routine Content::Routines::SearchExercises, as: :search

  protected

  def exec(options = {})

    assigned_to = options.delete(:assigned_to)
    not_assigned_to = options.delete(:not_assigned_to)

    relation = run(:search, options).outputs.items

    # Get exercises already assigned to a user
    unless assigned_to.nil?
      relation = exercises_assigned_to(relation: relation, roles: assigned_to)
    end

    # Get exercises not already assigned to a user
    unless not_assigned_to.nil?
      used = exercises_assigned_to(relation: relation, roles: not_assigned_to)
               .reorder(nil).limit(nil)
      relation = relation.where{id.not_in used.select(:id)}
    end

    # TODO: use wrapper
    outputs[:items] = relation.to_a

  end

  def exercises_assigned_to(relation:, roles:)
    relation.joins(
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
              entity_role_id: [roles].flatten.compact.collect{|r| r.id}
            }
          }
        }
      }
    )
  end

end
