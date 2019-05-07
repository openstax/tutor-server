module Settings
  module Biglearn

    class << self

      def student_clues_algorithm_name
        Settings::Db.store.biglearn_student_clues_algorithm_name
      end

      def teacher_clues_algorithm_name
        Settings::Db.store.biglearn_teacher_clues_algorithm_name
      end

      def assignment_spes_algorithm_name
        Settings::Db.store.biglearn_assignment_spes_algorithm_name
      end

      def assignment_pes_algorithm_name
        Settings::Db.store.biglearn_assignment_pes_algorithm_name
      end

      def practice_worst_areas_algorithm_name
        Settings::Db.store.biglearn_practice_worst_areas_algorithm_name
      end

    end

  end
end
