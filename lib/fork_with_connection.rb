module ForkWithConnection
  # Logic for forking connections
  def fork_with_connection
    # Store the ActiveRecord connection information
    ar_connection_config = ActiveRecord::Base.remove_connection

    fork do
      # Tracking if the op failed for the Process exit
      exit_status = true

      begin
        # Reconnect to the database for AR
        ActiveRecord::Base.establish_connection(ar_connection_config)

        # Reconnect to Redis for the Rails cache
        Rails.cache.reconnect

        # Reconnect to Redis for Jobba
        Jobba.redis.client.reconnect

        # Reconnect to Redis for Biglearn fake client if stubbing is enabled
        OpenStax::Biglearn::Api.client.store.reconnect \
          if OpenStax::Biglearn::Api.client.is_a? OpenStax::Biglearn::Api::FakeClient

        # This is needed to re-initialize the random number generator after forking
        # (if you want diff random numbers generated in the forks)
        srand

        # Run the closure passed to the fork_with_new_connection method
        exit_status = yield
      rescue Exception => exception
        Rails.logger.fatal do
          "Child process failed with exception: #{exception}\n#{exception.backtrace.first}"
        end

        # The op failed, so note it for the Process exit
        exit_status = false
      ensure
        # Sanitize the exit value
        # If the block returned nil, exit with success
        exit_status = case exit_status
        when Integer
          exit_status
        when NilClass
          true
        else
          !!exit_status
        end

        # Exit without running any at_exit hooks (leave those to the parent process)
        exit! exit_status
      end
    end.tap do |pid|
      # Restore the ActiveRecord connection information (for the main process)
      ActiveRecord::Base.establish_connection(ar_connection_config)
    end
  end
end
