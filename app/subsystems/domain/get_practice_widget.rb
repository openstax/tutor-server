class Domain::GetPracticeWidget
  lev_routine express_output: :task

  uses_routine Tasks::Api::GetPracticeTask,
               translations: { outputs: { type: :verbatim } }

  protected

  def exec(role:)
    run(Tasks::Api::GetPracticeTask, role: role)
  end
end