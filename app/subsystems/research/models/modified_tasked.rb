class Research::Models::ModifiedTasked < Research::Models::StudyBrain

  def add_instance_method
    instance_eval do
      eval(<<-EOM)
      def modified_tasked(cohort:, tasked:)
        with_manipulation(cohort: cohort, target: tasked) do|manipulation|
          #{code}
        end
        return { tasked: tasked }
      end
      EOM
    end
  end

end
