module OpenStax::Biglearn::Locks
  def with_course_locks(course_ids)
    CourseProfile::Models::Course.transaction do
      # We use advisory locks to prevent rollbacks
      # The advisory locks actually last until the end of the transaction,
      # because we use transaction-based locks
      # We use sort here to prevent deadlocks when locking the courses
      [course_ids].flatten.compact.sort.each do |course_id|
        lock_name = "biglearn_course_#{course_id}"
        CourseProfile::Models::Course.with_advisory_lock(lock_name)
      end

      yield
    end
  end

  def with_ecosystem_locks(ecosystem_ids)
    Content::Models::Ecosystem.transaction do
      # We use advisory locks to prevent rollbacks
      # The advisory locks actually last until the end of the transaction,
      # because we use transaction-based locks
      # We use sort here to prevent deadlocks when locking the ecosystems
      [ecosystem_ids].flatten.compact.sort.each do |ecosystem_id|
        lock_name = "biglearn_ecosystem_#{ecosystem_id}"
        Content::Models::Ecosystem.with_advisory_lock(lock_name)
      end

      yield
    end
  end
end
