module Sprint003
  class Main

    lev_routine

    uses_routine OpenStax::Accounts::Dev::CreateAccount, 
                 as: :create_account,
                 translations: { outputs: {type: :verbatim} }


  protected

    def exec(username_or_user:, opens_at: Time.now)

      if username_or_user.is_a? String
        run(:create_account, username: username_or_user)
        user = UserMapper.account_to_user(outputs[:account])
      else
        user = username_or_user
      end

      ###########################################################################
      #
      # Create a new Assistant record pointing to the sprint 3 assistant code
      # 

      assistant = ::Assistant.create(code_class_name: "Sprint003::Assistant")

      ###########################################################################
      #
      # Simulate the configuration of a reading task
      #

      # Simulate the UI requesting a blank task plan (a GET for a new task plan)

      study_task_plan = assistant.new_task_plan(:study)

      # Simulate UI submitting settings and selecting a taskee

      study_task_plan.title = "Reading"
      study_task_plan.opens_at = opens_at
      study_task_plan.configuration = {
        steps: [
          {
            title: "Section 2.1",
            type: "reading",
            url: "http://archive.cnx.org/contents/3e1fc4c6-b090-47c1-8170-8578198cc3f0@8.html" 
          }
        ]
      }

      tasking_plan = TaskingPlan.new(target: user)

      # Simulate the POST to create the TaskPlan (from the info set directly above)
      
      study_task_plan.owner = assistant # no where else to hang it for this sprint                           
      study_task_plan.save
      transfer_errors_from(study_task_plan, {verbatim: true}, true)
      study_task_plan.tasking_plans << tasking_plan

      # Check that the task plan's common settings and its specific configuration are valid
      # (the common check uses TaskPlan's built-in AR validations)

      assistant.validate_task_plan(study_task_plan)

      # If no errors, immediately create and distribute the tasks

      assistant.create_and_distribute_tasks(study_task_plan)

      ###########################################################################
      #
      # Simulate the configuration of a homework task
      #

      # homework_task_plan = assistant.new_task_plan(:homework)




    end

  end
end