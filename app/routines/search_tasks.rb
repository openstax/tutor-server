class SearchTasks

  lev_routine transaction: :no_transaction

  uses_routine OpenStax::Utilities::SearchAndOrganizeRelation,
               as: :search,
               errors_are_fatal: false,
               translations: {outputs: {type: :verbatim}}

  protected

  SEARCH_PROC = lambda { |with|
    with.default_keyword :id

    with.keyword :user_id do |ids|
      ids.each do |i|
        sanitized_ids = to_number_array(i)
        next @items = @items.none if sanitized_ids.empty?
        @items = @items.includes(:assigned_tasks).joins(:assigned_tasks)
                       .where{assigned_tasks.user_id.in sanitized_ids}
      end
    end

    with.keyword :id do |ids|
      ids.each do |i|
        sanitized_ids = to_number_array(i)
        next @items = @items.none if sanitized_ids.empty?
        @items = @items.where{id.in sanitized_ids}
      end
    end
  }

  SORTABLE_FIELDS = [:due_at, :opens_at, :created_at, :id]

  def exec(params:, **options)
    options[:eager_load_tasks] = true unless options.has_key?(:eager_load_tasks)
    relation = options[:eager_load_tasks] ? Task.preload(:details) : Task.unscoped

    run(:search, relation: relation, search_proc: SEARCH_PROC,
                 sortable_fields: SORTABLE_FIELDS, params: params)
  end

end
