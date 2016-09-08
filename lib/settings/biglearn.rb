module Settings
  module Biglearn

    class << self

      def client
        # This code can be called when creating a database (before the settings table is created).
        # In that case, the setting has never been set, so the correct value is the default value.
        return Settings::Db.store.defaults[:biglearn_client] \
          unless ActiveRecord::Base.connection.table_exists? 'settings'

        # Changes to this setting in the middle of a test aren't always
        # reflected in the cached value, so reset it. Similar to calling
        # `reload!` on an activerecord in a spec, just doing it here because
        # it is easy to forget in specs.
        Settings::Db.store.object('biglearn_client').try(:expire_cache) if Rails.env.test?

        Settings::Db.store.biglearn_client
      end

    end

  end
end
