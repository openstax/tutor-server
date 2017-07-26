module Settings
  module Payments

    class << self

      def payments_enabled
        Settings::Db.store.payments_enabled
      end

      def payments_enabled=(value)
        Settings::Db.store.payments_enabled = value
        Settings::Db.store.object('payments_enabled').expire_cache
      end

      def student_grace_period_days
        Settings::Db.store.student_grace_period_days
      end

      def student_grace_period_days=(days)
        Settings::Db.store.student_grace_period_days = days
        Settings::Db.store.object('student_grace_period_days').expire_cache
      end

    end

  end
end
