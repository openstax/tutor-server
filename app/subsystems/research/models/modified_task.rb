class Research::Models::ModifiedTask < Research::Models::StudyBrain

  def add_instance_method
    def modified_task(cohort:, task:)
      with_manipulation(cohort: cohort, target: task) do |manipulation|
        eval code
      end

      { task: task }
    end
  end

end
