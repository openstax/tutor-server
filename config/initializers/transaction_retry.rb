# TransactionRetry.max_retries = 3
# TransactionRetry.wait_times = [0, 1, 2, 4, 8, 16, 32] # seconds to sleep after retry n
TransactionRetry.retry_on = ActiveRecord::PreparedStatementCacheExpired # or an array of classes is valid too (ActiveRecord::TransactionIsolationConflict is by default always included)
# TransactionRetry.before_retry = ->(retry_num, error) { ... }
