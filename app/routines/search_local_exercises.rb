class SearchLocalExercises

  lev_routine express_output: :items

  uses_routine Content::Routines::SearchExercises, as: :search
  uses_routine Tasks::GetAssignedExercises, as: :assigned

  protected

  def exec(options = {})

    assigned_to = options.delete(:assigned_to)
    not_assigned_to = options.delete(:not_assigned_to)

    relation = run(:search, options).outputs.items

    # Get exercises already assigned to a user
    unless assigned_to.nil?
      relation = run(:assigned, relation: relation, roles: assigned_to).outputs.exercises
    end

    # Get exercises not already assigned to a user
    unless not_assigned_to.nil?
      used = run(:assigned, relation: relation, roles: not_assigned_to)
               .outputs.exercises.reorder(nil).limit(nil)
      relation = relation.where{id.not_in used.pluck(:id)}
    end

    outputs[:items] = Entity::Relation.new(relation).to_a

  end

end
