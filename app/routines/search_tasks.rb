class SearchTasks
  lev_routine transaction: :no_transaction

  uses_routine OrganizeSearchResults,
               translations: { outputs: {type: :verbatim} }

protected

  def exec(query, options={})

    tasks = Task.all
    
    KeywordSearch.search(query) do |with|

      with.keyword :user_id do |user_ids|
        tasks = tasks.where{user_id.in my{user_ids}}
      end

      with.keyword :id do |ids|
        tasks = tasks.where{id.in ids}
      end

    end

    run(OrganizeSearchResults, tasks, 
                               page: options[:page],
                               per_page: options[:per_page],
                               order_by: options[:order_by],
                               sortable_fields: ['due_at', 'opens_at', 'created_at', 'id'], 
                               default_sort_field: 'id')

    outputs[:tasks] = outputs[:relation]
    outputs[:query] = query

    # # If the query didn't result in any restrictions, either because it was blank
    # # or didn't have a keyword from above with appropriate values, then return no
    # # results.

    # tasks = Task.none if Task.all == tasks

    # # Pagination -- this is where we could modify the incoming values for page
    # # and per_page, depending on options

    # page = options[:page] || 0
    # per_page = options[:per_page] || 20

    # tasks = tasks.limit(per_page).offset(per_page*page)

    # #
    # # Ordering
    # #

    # # Parse the input
    # order_bys = (options[:order_by] || '').split(',').collect{|ob| ob.strip.split(' ')}

    # # Toss out bad input, provide default direction
    # order_bys = order_bys.collect do |order_by|
    #   field, direction = order_by
    #   next if !SORTABLE_FIELDS.include?(field)
    #   direction ||= SORT_ASCENDING
    #   next if direction != SORT_ASCENDING && direction != SORT_DESCENDING
    #   [field, direction]
    # end

    # order_bys.compact!

    # # Use a default sort if none provided
    # order_bys = ['id', SORT_ASCENDING] if order_bys.empty?

    # # Convert to query style
    # order_bys = order_bys.collect{|order_by| "#{order_by[0]} #{order_by[1]}"}

    # # Make the ordering call
    # order_bys.each do |order_by|
    #   tasks = tasks.order(order_by)
    # end

    # # Make sure we don't have duplicates (can happen with the joins)

    # tasks = tasks.uniq

    # # Translate to routine outputs

    # outputs[:tasks] = tasks
    # outputs[:query] = query
    # outputs[:per_page] = per_page
    # outputs[:page] = page
    # outputs[:order_by] = order_bys.join(', ') # convert back to one string
    # outputs[:num_matching_tasks] = tasks.except(:offset, :limit, :order).count
  end

end