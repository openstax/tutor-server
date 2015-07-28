module Tasks
  class CreatePracticeWidgetTask
    lev_routine express_output: :task

    uses_routine BuildTask,
      translations: { outputs: { type: :verbatim } },
      as: :build_task

    protected
    def exec(add_related_content:, task_type: :mixed_practice, exercises:)
      task_type ||= :mixed_practice # in case 'nil' is passed deliberately

      # In a multi-web server environment, it is possible for one server to create
      # the practice task and another to request it very quickly and if the server
      # times are not completely sync'd the request can be reject because the task
      # looks non open.  When we have PracticeTasks maybe they can not have an opens_at
      # but for now HACK it by setting it to open in the near past.
      task_time = 10.minutes.ago

      run(:build_task, task_type: task_type,
                       title: 'Practice',
                       opens_at: task_time,
                       feedback_at: task_time)

      exercises.each do |exercise|
        step = Tasks::Models::TaskStep.new(task: outputs.task)

        step.tasked = TaskExercise[exercise: exercise, task_step: step]

        if add_related_content
          step.add_related_content(get_related_content_for(exercise))
        end

        outputs.task.task_steps << step
      end

      outputs.task.save!
    end

    private
    def get_related_content_for(content_exercise)
      page = content_exercise_page(content_exercise)

      { title: page.title, chapter_section: page.chapter_section }
    end

    def content_exercise_page(content_exercise)
      los = content_exercise.los + content_exercise.aplos
      pages = Content::Models::Page.joins{page_tags.tag}
                                   .where{page_tags.tag.value.in los}

      if pages.one?
        pages.first
      else
        raise "#{pages.count} pages found for exercise #{content_exercise.url}"
      end
    end
  end
end
