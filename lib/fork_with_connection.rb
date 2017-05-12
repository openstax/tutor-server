# Logic for forking connections

module Tutor
  def self.fork_with_connection

    # Store the ActiveRecord connection information
    ar_connection_config = ActiveRecord::Base.remove_connection

    pid = fork do
      # tracking if the op failed for the Process exit
      exit_status = 0

      begin
        ActiveRecord::Base.establish_connection(ar_connection_config)
        # settings are cached in Redis by rails-settings-cached
        Rails.cache.reconnect

        Jobba.redis.client.reconnect

        # reconnect fake client if Biglearn stubbing is enabled
        OpenStax::Biglearn::Api.client.store.reconnect \
          if OpenStax::Biglearn::Api.client.is_a? OpenStax::Biglearn::Api::FakeClient

        # This is needed to re-initialize the random number generator after forking (if you want diff random numbers generated in the forks)
        srand

        # Run the closure passed to the fork_with_new_connection method
        exit_status = yield

      rescue => e
        STDERR.puts "Forked operation failed with exception: #{e}"

        # the op failed, so note it for the Process exit
        exit_status = 1

      ensure
        ActiveRecord::Base.remove_connection
        Process.exit! exit_status.is_a?(Fixnum) ? exit_status : 0
      end
    end

    # Restore the ActiveRecord connection information
    ActiveRecord::Base.establish_connection(ar_connection_config)

    #return the process id
    pid
  end
end
