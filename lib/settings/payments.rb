module Settings
  module Payments

    class << self

      def payments_enabled
        Settings::Db.payments_enabled
      end

      def payments_enabled=(value)
        Settings::Db.payments_enabled = value
      end

      def student_grace_period_days
        Settings::Db.student_grace_period_days
      end

      def student_grace_period_days=(days)
        Settings::Db.student_grace_period_days = days
      end

    end

  end
end
