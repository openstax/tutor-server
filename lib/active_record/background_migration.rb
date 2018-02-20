require 'fork_with_connection'

module ActiveRecord::BackgroundMigration
  def self.included(base)
    base.include ForkWithConnection
  end

  # Until we get Rails 5.2 https://github.com/rails/rails/pull/31173
  # we must ensure we are not in a transaction
  # After Rails 5.2, we could do something fancier
  def in_background(&block)
    raise 'in_background cannot be used in a transaction (use disable_ddl_transaction!)' \
      if ActiveRecord::Base.connection.transaction_open?

    pid = fork_with_connection do
      Process.daemon true
      @connection = ActiveRecord::Base.connection

      class_name = self.class.name
      pid = Process.pid

      Rails.logger.info { "#{class_name} background migration (pid: #{pid}) started" }

      block.call

      Rails.logger.info { "#{class_name} background migration (pid: #{pid}) successful" }
    end

    # Will only wait for the other process to call Process.daemon
    Process.wait pid
  end
end

ActiveRecord::Migration.include ActiveRecord::BackgroundMigration
