module Settings
  module Salesforce

    class << self

      def import_real_salesforce_courses
        Settings::Db.store.import_real_salesforce_courses
      end

      def import_real_salesforce_courses=(bool)
        Settings::Db.store.import_real_salesforce_courses = bool
      end

    end

  end
end
