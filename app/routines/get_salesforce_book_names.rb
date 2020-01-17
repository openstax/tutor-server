class GetSalesforceBookNames
  lev_routine transaction: :no_transaction, express_output: :book_names

  def exec(force_cache_miss = false)
    unless force_cache_miss
      outputs.book_names = ActiveForce.cache_store.get('book_names')
      return unless outputs.book_names.nil?
    end

    begin
      outputs.book_names = OpenStax::Salesforce::Remote::Book.all.map(&:name)
    rescue IllegalState
      # Ignore IllegalState exceptions thrown by openstax_salesforce
    else
      # This block runs if no exceptions were raised
      ActiveForce.cache_store.set('book_names', outputs.book_names)
    end
  end
end
