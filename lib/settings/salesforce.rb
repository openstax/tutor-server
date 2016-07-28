module Settings
  module Salesforce

    class << self

      def import_real_salesforce_courses
        Settings::Db.store.import_real_salesforce_courses
      end

      def import_real_salesforce_courses=(bool)
        Settings::Db.store.import_real_salesforce_courses = bool
      end

      def term_years_to_import
        Settings::Db.store.term_years_to_import
      end

      def term_years_to_import=(string)
        Settings::Db.store.term_years_to_import = string
      end

    end

  end
end
