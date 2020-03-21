FactoryBot.define do
  factory :tasks_task_step, class: '::Tasks::Models::TaskStep' do
    tasked_type { :tasks_tasked_reading }

    group_type  { Tasks::Models::TaskStep.group_types.keys.sample.to_sym }
    is_core     { fixed_group? || personalized_group? }

    transient do
      url       { nil }
      content   { nil }
      title     { nil }
      skip_task { false }
    end

    after(:build) do |task_step, evaluator|
      tasked_options = {
        task_step: task_step,
        url: evaluator.url,
        title: evaluator.title
      }.compact
      task_step.tasked ||= FactoryBot.build evaluator.tasked_type, tasked_options

      task_options = { task_steps: [ task_step ] }
      task_step.task ||= FactoryBot.build(:tasks_task, task_options) unless evaluator.skip_task

      if task_step.page.nil?
        if evaluator.skip_task
          task_step.page = build(:content_book, :standard_contents_1).pages.sample
        else
          ecosystem = task_step.task.ecosystem
          book = task_step.task.ecosystem.books.sample

          if book.nil?
            book = build :content_book, :standard_contents_1, ecosystem: task_step.task.ecosystem
            task_step.task.ecosystem.books << book
          end

          task_step.page = book.pages.sample

          if task_step.page.nil?
            task_step.page = build :content_page, book: book
            book.pages << task_step.page
          end
        end
      end

      page = task_step.page
      page.content = evaluator.content unless evaluator.content.nil?
      page.save!
      Content::Routines::TransformAndCachePageContent.call book: page.book, pages: [ page ]
    end
  end
end
