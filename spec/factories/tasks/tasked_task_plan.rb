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
      cnx_page  = OpenStax::Cnx::V1::Page.new(
        hash: {'id' => '092bbf0d-0729-42ce-87a6-fd96fd87a083',
               'title' => 'Force'}
      )
      book_part = FactoryGirl.create :content_book_part
      page      = Content::Routines::ImportPage.call(cnx_page: cnx_page, book_part: book_part)
                                               .outputs.page
      { page_ids: [page.id] }
    end

    after(:create) do |task_plan,evaluator|
      evaluator.number_of_students.times.each do
        user = FactoryGirl.create :user_profile
        role = Role::GetDefaultUserRole[user.entity_user]
        tp = FactoryGirl.create :tasks_tasking_plan, target: role, task_plan: task_plan
        task_plan.tasking_plans << tp
      end

      DistributeTasks.call(task_plan)
    end
  end
end
