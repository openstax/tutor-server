module Settings
  module Biglearn

    class << self

      def client
        # This code can be called when creating a database (before the settings table is created).
        # In that case, the setting has never been set, so the correct value is the default value.
        return Settings::Db.store.defaults[:biglearn_client] \
          unless ActiveRecord::Base.connection.table_exists? 'settings'

        Settings::Db.store.biglearn_client
      end

    end

  end
end
