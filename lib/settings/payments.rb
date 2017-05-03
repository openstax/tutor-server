module Settings
  module Payments

    class << self

      def student_grace_period_days
        Settings::Db.store.student_grace_period_days
      end

      def student_grace_period_days=(days)
        Settings::Db.store.student_grace_period_days = days
      end

    end

  end
end
