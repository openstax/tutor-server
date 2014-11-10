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
      # Create some dummy objects off which to hang things
      #

      klass = FactoryGirl.create(:klass)

      ###########################################################################
      #
      # Simulate that someone, sometime set up a bunch of exercises with topic tags;
      # for test purposes, assign one tag to the first half and another tag to the
      # second half.
      #

      exercise_urls = %w(
        http://quadbase.org/questions/q2153
        http://quadbase.org/questions/q2235
        http://quadbase.org/questions/q2154
        http://quadbase.org/questions/q2236
        http://quadbase.org/questions/q850
        http://quadbase.org/questions/q1200
        http://quadbase.org/questions/q4255
        http://quadbase.org/questions/q4258
        http://quadbase.org/questions/q4286
        http://quadbase.org/questions/q4317
        http://quadbase.org/questions/q4318
        http://quadbase.org/questions/q4332
      )

      exercise_definitions = []

      exercise_urls.each_with_index do |exercise_url, ii|
        topic_name = (ii < exercise_urls.length / 2) ? "topic_a" : "topic_b"

        exercise_definitions.push ExerciseDefinition.create(
          klass: klass,
          url: exercise_url,
          content: {
            background: "This is a #{topic_name} exercise from: #{exercise_url}. Einstein makes a 10 kg spaceship",
            parts:[
              {
                background: "The spaceship moves at <span data-math='\\dfrac{-b \\pm \\sqrt{b^2 - 4ac}}{2a}'></span> 1 m/s",
                questions:[
                  {
                    id: "123",
                    format: "short-answer",
                    stem: "What is the rest mass in kg?"
                  },
                  {
                    id: "234",
                    format: "multiple-choice",
                    stem: "What is the force if it slams into a wall?",
                    answers:[
                      {id: "id1", value: "10", content: "10 N"},
                      {id: "id2", value: "1", content: "1 N"}
                    ]
                  }
                ]
              }
            ]
          }
        )
        
        TagExerciseDefinitionWithTopic.call(exercise_definition: exercise_definitions.last, topic: topic_name)
      end

      ###########################################################################
      #
      # Create a new Assistant record pointing to the sprint 3 assistant code
      # 

      assistant = ::Assistant.create(code_class_name: "Sprint003::Assistant")

      ###########################################################################
      #
      # Simulate the configuration of the first homework
      #

      # Simulate the UI requesting a blank task plan (a GET for a new task plan)

      hw1_task_plan = assistant.new_task_plan(:homework)

      # Simulate UI submitting settings and selecting a taskee

      hw1_task_plan.title = "Homework 1"
      hw1_task_plan.opens_at = opens_at
      hw1_task_plan.configuration = {
        exercises: [
          {
            type: "manual",
            exercise_definition_id: exercise_definitions.first.id
          }
        ]
      }

      tasking_plan = TaskingPlan.new(target: user)

      # Simulate the POST to create the TaskPlan (from the info set directly above)
      
      hw1_task_plan.owner = klass
      hw1_task_plan.save
      transfer_errors_from(hw1_task_plan, {verbatim: true}, true)
      hw1_task_plan.tasking_plans << tasking_plan

      # Check that the task plan's common settings and its specific configuration are valid
      # (the common check uses TaskPlan's built-in AR validations)

      assistant.validate_task_plan(hw1_task_plan)

      # If no errors, immediately create and distribute the tasks

      assistant.create_and_distribute_tasks(hw1_task_plan)

      ###########################################################################
      #
      # Simulate the configuration of a reading task
      #

      # Simulate the UI requesting a blank task plan (a GET for a new task plan)

      study_task_plan = assistant.new_task_plan(:study)

      # Simulate UI submitting settings and selecting a taskee

      study_task_plan.title = "Study"
      study_task_plan.opens_at = opens_at
      study_task_plan.configuration = {
        steps: [
          {
            title: "Section 2.1",
            type: "reading",
            url: "http://archive.cnx.org/contents/3e1fc4c6-b090-47c1-8170-8578198cc3f0@8.html" 
          },
          {
            title: "Faucet Simulation",
            type: "interactive",
            url: "http://connexions.github.io/simulations" 
          }
        ]
      }

      tasking_plan = TaskingPlan.new(target: user)

      # Simulate the POST to create the TaskPlan (from the info set directly above)
      
      study_task_plan.owner = klass
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

      # Simulate the UI requesting a blank task plan (a GET for a new task plan)

      hw2_task_plan = assistant.new_task_plan(:homework)

      # Simulate UI submitting settings and selecting a taskee

      hw2_task_plan.title = "Homework 2"
      hw2_task_plan.opens_at = opens_at
      hw2_task_plan.configuration = {   # this could be simpler -- just list of manual exercises, then spaced config, then personalized config
        exercises: [
          {
            type: "manual",
            exercise_definition_id: exercise_definitions.last.id
          },
          {
            type: "from_topic",
            topic: "topic_a",
            count: 1
          },
          {
            type: "personalized",
            count: 1
          }
        ]
      }

      # Assistant should use a SpacedPracticeOnAnyWorkedProblem block

      tasking_plan = TaskingPlan.new(target: user)

      # Simulate the POST to create the TaskPlan (from the info set directly above)
      
      hw2_task_plan.owner = klass
      hw2_task_plan.save
      transfer_errors_from(hw2_task_plan, {verbatim: true}, true)
      hw2_task_plan.tasking_plans << tasking_plan

      # Check that the task plan's common settings and its specific configuration are valid
      # (the common check uses TaskPlan's built-in AR validations)

      assistant.validate_task_plan(hw2_task_plan)

      # If no errors, immediately create and distribute the tasks

      assistant.create_and_distribute_tasks(hw2_task_plan)

    end

  end
end