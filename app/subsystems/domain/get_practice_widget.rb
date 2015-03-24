class Domain::GetPracticeWidget
  lev_routine

  uses_routine Tasks::Api::GetPracticeTask,
               translations: { outputs: { type: :verbatim } }

  protected

  def exec(role:)
    run(Tasks::Api::GetPracticeTask, role: role)
  end
end