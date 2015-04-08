class GetPracticeWidget
  lev_routine express_output: :task

  uses_routine Tasks::GetPracticeTask,
               translations: { outputs: { type: :verbatim } }

  protected

  def exec(role:)
    run(Tasks::GetPracticeTask, role: role)
  end
end
