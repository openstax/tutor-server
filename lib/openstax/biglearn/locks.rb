module OpenStax::Biglearn::Locks
  def with_biglearn_locks(model_class:, model_ids:)
    model_class.transaction do
      # We use advisory locks to prevent rollbacks
      # The advisory locks actually last until the end of the transaction,
      # because we use transaction-based locks
      table_name = model_class.table_name

      # We use sort here to prevent deadlocks when locking the models
      [model_ids].flatten.compact.sort.each do |model_id|
        lock_name = "biglearn_#{table_name}_#{model_id}"
        result = model_class.with_advisory_lock(lock_name)
        raise "Unable to acquire lock #{lock_name}" if result == false # nil is OK
      end

      yield
    end
  end
end
