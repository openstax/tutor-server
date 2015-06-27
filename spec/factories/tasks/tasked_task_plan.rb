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
      book_part = FactoryGirl.create :content_book_part
      page    = Content::Routines::ImportPage.call(cnx_page: cnx_page, book_part: book_part)
                                             .outputs.page
      page.chapter_section = [1, 1]
      page.save!
      { page_ids: [page.id.to_s] }
    end

    after(:create) do |task_plan, evaluator|
      course = task_plan.owner
      period = course.periods.first || CreatePeriod[course: course]

      evaluator.number_of_students.times.each do
        user = FactoryGirl.create :user_profile
        role = Role::GetDefaultUserRole[user.entity_user]
        CourseMembership::AddStudent.call(period: period, role: role)
        tp = FactoryGirl.create :tasks_tasking_plan, target: role, task_plan: task_plan
        task_plan.tasking_plans << tp
      end

      DistributeTasks.call(task_plan)
      task_plan.reload
    end
  end
end
