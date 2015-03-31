class SearchTasks

  lev_routine transaction: :no_transaction

  uses_routine OSU::SearchAndOrganizeRelation,
               as: :search,
               translations: { outputs: { type: :verbatim } }
  uses_routine Role::GetUserRoles,
               translations: { outputs: { type: :verbatim } }

  SORTABLE_FIELDS = {
    'due_at' => :due_at,
    'opens_at' => :opens_at,
    'created_at' => :created_at,
    'id' => :id
  }

  protected

  def exec(params, options = {})
    options[:eager_load_tasks] = true unless options.has_key?(:eager_load_tasks)
    relation = options[:eager_load_tasks] ? \
                 Tasks::Models::Task.includes(:task_steps) : Task.unscoped

    run(:search, relation: relation,
                 sortable_fields: SORTABLE_FIELDS,
                 params: params) do |with|
      with.default_keyword :id

      with.keyword :user_id do |ids|
        ids.each do |i|
          sanitized_ids = to_number_array(i)          
          next @items = @items.none if sanitized_ids.empty?

          run(Role::GetUserRoles, sanitized_ids)
          role_ids = outputs.delete(:roles).collect{|r| r.id}

          @items = @items.includes(:taskings).joins(:taskings)
                         .where{taskings.user_id.in role_ids}
        end
      end

      with.keyword :id do |ids|
        ids.each do |i|
          sanitized_ids = to_number_array(i)
          next @items = @items.none if sanitized_ids.empty?
          @items = @items.where{id.in sanitized_ids}
        end
      end
    end
  end

end
