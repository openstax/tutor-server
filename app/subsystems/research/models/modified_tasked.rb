class Research::Models::ModifiedTasked < Research::Models::StudyBrain

  def add_instance_method
    def modified_tasked(cohort:, tasked:)
      with_manipulation(cohort: cohort, target: tasked) do |manipulation|
        eval code
      end

      { tasked: tasked }
    end
  end

end
