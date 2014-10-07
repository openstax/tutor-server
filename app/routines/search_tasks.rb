class SearchTasks
  lev_routine transaction: :no_transaction

  uses_routine OrganizeSearchResults,
               translations: { outputs: {type: :verbatim} }

protected

  def exec(query, options={})

    tasks = Task.all
    
    KeywordSearch.search(query) do |with|

      with.keyword :user_id do |user_ids|
        tasks = tasks.joins{assigned_tasks}.where{assigned_tasks.user_id.in my{user_ids}}
      end

      with.keyword :id do |ids|
        tasks = tasks.where{id.in ids}
      end

    end

    # TODO include detailed tasks in the query -- just always tack on ".includes(:details)"??

    run(OrganizeSearchResults, tasks, 
                               page: options[:page],
                               per_page: options[:per_page],
                               order_by: options[:order_by],
                               sortable_fields: ['due_at', 'opens_at', 'created_at', 'id'], 
                               default_sort_field: 'id')

    outputs[:tasks] = outputs[:relation]
    outputs[:query] = query
  end

end