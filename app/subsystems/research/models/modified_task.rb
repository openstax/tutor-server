class Research::Models::ModifiedTask < Research::Models::StudyBrain

  def add_instance_method
    instance_eval do
      eval(<<-EOS)
      def modified_task(cohort:, task:)
        with_manipulation(cohort: cohort, target: task) do|manipulation|
          #{code}
        end
        return { task: task }
      end
      EOS
    end
  end

end
