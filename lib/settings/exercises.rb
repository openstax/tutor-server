module Settings
  module Exercises

    class << self

      def excluded_ids
        Settings::Db.store.excluded_ids
      end

      def excluded_ids=(ids)
        Settings::Db.store.excluded_ids = ids
      end

    end

  end
end
