# Takes a search result relation and applies standard (configurable) cleanup
# and processing to it:
#
#   1) Prevents returning all records if :do_not_return_everything is true
#   2) Paginates if :page and :per_page set
#   3) Sorts -- requires an array of :sortable_fields, with optional setting
#      of :sort_ascending and :sort_descending strings (default to 'ASC' and
#      'DESC', respectively, and optional setting of a :default_sort_field)
#   4) Eliminates duplicates
#   5) Counts all matches

class OrganizeSearchResults
  lev_routine transaction: :no_transaction

protected

  def exec(relation, options={})

    model = relation.model

    # If the query didn't result in any restrictions, either because it was blank
    # or didn't have a keyword from above with appropriate values, then return no
    # results.

    do_not_return_everything = options.has_key?(:do_not_return_everything) ? 
                                 options[:do_not_return_everything] : 
                                 true

    relation = model.none if do_not_return_everything && model.all == relation

    # Pagination -- this is where we could modify the incoming values for page
    # and per_page, depending on options

    page = options[:page]
    per_page = options[:per_page]

    relation = relation.limit(per_page).offset(per_page*page) if page.present? && per_page.present?

    #
    # Ordering
    #

    sortable_fields = options[:sortable_fields]
    sort_ascending = options[:sort_ascending] || 'ASC'
    sort_descending = options[:sort_descending] || 'DESC'
    default_sort_field = options[:default_sort_field]

    # Parse the input
    order_bys = (options[:order_by] || '').split(',').collect{|ob| ob.strip.split(' ')}

    # Toss out bad input, provide default direction
    order_bys = order_bys.collect do |order_by|
      field, direction = order_by
      next if !sortable_fields.include?(field)
      direction ||= sort_ascending
      next if direction != sort_ascending && direction != sort_descending
      [field, direction]
    end

    order_bys.compact!

    # Use a default sort if available and no explicit sort provided
    order_bys = [[default_sort_field, sort_ascending]] if default_sort_field.present? && order_bys.empty?

    # Convert to query style
    order_bys = order_bys.collect{|order_by| "#{order_by[0]} #{order_by[1]}"}

    # Make the ordering call
    order_bys.each do |order_by|
      relation = relation.order(order_by)
    end

    # Make sure we don't have duplicates (can happen with the joins)

    allow_duplicates ||= false
    relation = relation.uniq unless allow_duplicates

    # Translate to routine outputs

    outputs[:relation] = relation
    outputs[:per_page] = per_page
    outputs[:page] = page
    outputs[:order_by] = order_bys.join(', ') # convert back to one string
    outputs[:num_matching_items] = relation.except(:offset, :limit, :order).count
  end

end