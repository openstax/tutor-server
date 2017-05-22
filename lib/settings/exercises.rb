module Settings
  module Exercises

    class << self

      def excluded_ids
        Settings::Db.store.excluded_ids
      end

      def excluded_ids=(ids)
        Settings::Db.store.excluded_ids = ids
      end

      def excluded_at
        result = ActiveRecord::Base.connection.execute(
          <<-SQL.strip_heredoc
            SELECT "updated_at"
            FROM "settings"
            WHERE "var" = 'excluded_ids'
              AND "thing_type" IS NULL
              AND "thing_id" IS NULL
            ORDER BY "settings"."id"
            LIMIT 1;
          SQL
        ).first

        return if result.nil?

        result.fetch('updated_at').to_time
      end

    end

  end
end
