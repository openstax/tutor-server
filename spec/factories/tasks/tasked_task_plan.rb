FactoryGirl.define do
  factory :tasked_task_plan, parent: :tasks_task_plan do

    type 'reading'
    assistant { Tasks::Models::Assistant.find_by(
                  code_class_name: 'Tasks::Assistants::IReadingAssistant'
                ) || FactoryGirl.create(
                  :tasks_assistant, code_class_name: 'Tasks::Assistants::IReadingAssistant'
                ) }

    transient do
      number_of_students 10
    end

    settings do
      cnx_page = OpenStax::Cnx::V1::Page.new(
        hash: { 'id' => '640e3e84-09a5-4033-b2a7-b7fe5ec29dc6',
                'title' => 'Newton\'s First Law of Motion: Inertia' }
      )

      chapter = FactoryGirl.create :content_chapter

      VCR.use_cassette("TaskedTaskPlan/with_inertia", VCR_OPTS) do
        @page = Content::Routines::ImportPage[cnx_page: cnx_page, chapter: chapter,
                                              book_location: [1, 1]]
      end

      Content::Routines::PopulateExercisePools[pages: @page]

      AddEcosystemToCourse[course: owner, ecosystem: chapter.book.ecosystem]

      { page_ids: [@page.id.to_s] }
    end

    after(:create) do |task_plan, evaluator|
      course = task_plan.owner
      period = course.periods.first || CreatePeriod[course: course]

      task_plan.tasking_plans = evaluator.number_of_students.times.collect do |ii|
        user = create :user_profile
        role = Role::GetDefaultUserRole[user.entity_user]
        CourseMembership::AddStudent.call(period: period, role: role)
        build :tasks_tasking_plan, task_plan: task_plan, target: role
      end
      task_plan.save!

      DistributeTasks.call(task_plan)
      task_plan.reload
    end
  end
end
