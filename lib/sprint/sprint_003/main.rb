module Sprint003
  class Main

    lev_routine

    uses_routine OpenStax::Accounts::Dev::CreateAccount, 
                 as: :create_account,
                 translations: { outputs: {type: :verbatim} }


  protected

    def exec(username)
      run(:create_account, username: username)
      user = UserMapper.account_to_user(outputs[:account])

      ###########################################################################
      #
      # Create a new Assistant record pointing to a Sprint003Assistant code
      # 

      assistant = ::Assistant.create(code_class_name: "Sprint003::Assistant")

      ###########################################################################
      #
      # Simulate the configuration of a reading task
      #

      # Simulate the UI requesting a blank task plan

      study_task_plan = assistant.new_task_plan(:study).tap do |task_plan|
        task_plan.owner = assistant # no where else to hang it for this sprint
        task_plan.opens_at = Time.now
      end

      study_task_plan.save
      transfer_errors_from(study_task_plan, {verbatim: true}, true)

      # Simulate UI submitting settings and selecting a taskee

      study_task_plan.title = "Reading"
      study_task_plan.opens_at = Time.now
      study_task_plan.configuration = {
        steps: [
          {
            title: "Section 2.1",
            type: "reading",
            url: "http://archive.cnx.org/contents/3e1fc4c6-b090-47c1-8170-8578198cc3f0@8.html" 
          }
        ]
      }

      study_task_plan.tasking_plans << TaskingPlan.new(target: user)
      
      study_task_plan.save
      transfer_errors_from(study_task_plan, {verbatim: true}, true)

      assistant.create_and_distribute_tasks(study_task_plan)

      ###########################################################################
      #
      # Simulate the configuration of a homework task
      #

      # homework_task_plan = assistant.new_task_plan(:homework)




    end

  end
end