class Research::Models::UpdateStudentTasked < Research::Models::StudyBrain

  def add_instance_method
    instance_eval do
      eval(<<-EOM)
      def update_student_tasked(tasked:)
        #{code}
        return { tasked: tasked }
      end
      EOM
    end
  end

end
