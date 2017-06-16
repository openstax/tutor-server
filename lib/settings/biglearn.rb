module Settings
  module Biglearn

    # This code can be called when creating a database (before the settings table is created).
    # In that case, the setting has never been set, so the correct value is the default value.
    class << self

      def client_name
        return Settings::Db.store.defaults[:biglearn_client_name] \
          unless ActiveRecord::Base.connection.table_exists? 'settings'

        Settings::Db.store.biglearn_client_name
      end

      def client_name=(new_biglearn_client_name)
        Settings::Db.store.biglearn_client_name = new_biglearn_client_name
      end

      def student_clues_algorithm_name
        return Settings::Db.store.defaults[:biglearn_student_clues_algorithm_name] \
          unless ActiveRecord::Base.connection.table_exists? 'settings'

        Settings::Db.store.biglearn_student_clues_algorithm_name
      end

      def teacher_clues_algorithm_name
        return Settings::Db.store.defaults[:biglearn_teacher_clues_algorithm_name] \
          unless ActiveRecord::Base.connection.table_exists? 'settings'

        Settings::Db.store.biglearn_teacher_clues_algorithm_name
      end

      def assignment_spes_algorithm_name
        return Settings::Db.store.defaults[:biglearn_assignment_spes_algorithm_name] \
          unless ActiveRecord::Base.connection.table_exists? 'settings'

        Settings::Db.store.biglearn_assignment_spes_algorithm_name
      end

      def assignment_pes_algorithm_name
        return Settings::Db.store.defaults[:biglearn_assignment_pes_algorithm_name] \
          unless ActiveRecord::Base.connection.table_exists? 'settings'

        Settings::Db.store.biglearn_assignment_pes_algorithm_name
      end

      def practice_worst_areas_algorithm_name
        return Settings::Db.store.defaults[:biglearn_practice_worst_areas_algorithm_name] \
          unless ActiveRecord::Base.connection.table_exists? 'settings'

        Settings::Db.store.biglearn_practice_worst_areas_algorithm_name
      end

    end

  end
end
