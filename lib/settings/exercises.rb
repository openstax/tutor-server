module Settings
  module Exercises

    class << self

      def excluded_uids
        Settings::Db.store.excluded_uids
      end

      def excluded_uids=(uids)
        Settings::Db.store.excluded_uids = uids
      end

      def excluded_pool_uuid
        Settings::Db.store.excluded_pool_uuid
      end

      def excluded_pool_uuid=(uuid)
        Settings::Db.store.excluded_pool_uuid = uuid
      end

    end

  end
end
