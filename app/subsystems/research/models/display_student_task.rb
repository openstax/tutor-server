class Research::Models::DisplayStudentTask < Research::Models::StudyBrain

  def add_instance_method
    instance_eval do
      eval(<<-EOS)
      def task_for_display(task:)
        #{code}
        return { task: task }
      end
      EOS
    end
  end

end
