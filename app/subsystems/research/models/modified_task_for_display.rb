class Research::Models::ModifiedTaskForDisplay < Research::Models::StudyBrain

  def add_instance_method
    instance_eval do
      eval(<<-EOS)
      def modified_task_for_display(cohort:, task:)
        #{code}
        return { task: task }
      end
      EOS
    end
  end

end
