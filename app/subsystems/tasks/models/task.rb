require_relative 'entity_extensions'

class Tasks::Models::Task < Tutor::SubSystems::BaseModel

  enum task_type: [:homework, :reading, :chapter_practice,
                   :page_practice, :mixed_practice]

  belongs_to :task_plan
  belongs_to :entity_task, class_name: 'Entity::Task',
                           dependent: :destroy,
                           foreign_key: 'entity_task_id'

  sortable_has_many :task_steps, on: :number,
                                 dependent: :destroy,
                                 autosave: true,
                                 inverse_of: :task
  has_many :taskings, dependent: :destroy, through: :entity_task

  validates :title, presence: true
  validates :due_at, timeliness: { on_or_after: :opens_at },
                     allow_nil: true,
                     if: :opens_at

  validate :opens_at_or_due_at

  def is_shared?
    taskings.size > 1
  end

  def past_due?(current_time: Time.now)
    !due_at.nil? && current_time > due_at
  end

  def feedback_available?(current_time: Time.now)
    !feedback_at.nil? && current_time >= feedback_at
  end

  def completed?
    self.task_steps.all?{|ts| ts.completed? }
  end

  def status
    # task is "completed" if all steps are completed,
    #         "in_progress" if some steps are completed and
    #         "not_started" if no steps are completed
    if self.completed?
      'completed'
    else
      in_progress = self.task_steps.any? { |ts| ts.completed? }
      in_progress ? 'in_progress' : 'not_started'
    end
  end

  def practice?
    page_practice? || chapter_practice? || mixed_practice?
  end

  def core_task_steps
    self.task_steps.select{|ts| ts.core_group?}
  end

  def spaced_practice_task_steps
    self.task_steps.select{|ts| ts.spaced_practice_group?}
  end

  def personalized_task_steps
    self.task_steps.select{|ts| ts.personalized_group?}
  end

  def core_task_steps_completed?
    self.core_task_steps.all?{|ts| ts.completed?}
  end

  def core_task_steps_completed_at
    return nil unless self.core_task_steps_completed?
    self.core_task_steps.collect{|ts| ts.completed_at}.max
  end

  def handle_task_step_completion!(completion_time: Time.now)
    populate_placeholders(core_completion_time: completion_time) if core_task_steps_completed?
  end

  def exercise_count
    exercise_steps.count
  end

  def completed_exercise_count
    completed_exercise_steps.count
  end

  def correct_exercise_count
    exercise_steps.select{|step| step.tasked.is_correct?}.count
  end

  def exercise_steps
    task_steps.select{|task_step| task_step.exercise?}
  end

  def completed_exercise_steps
    exercise_steps.select{|step| step.completed?}
  end

  protected

  def opens_at_or_due_at
    return unless opens_at.blank? && due_at.blank?
    errors.add(:base, 'needs either the opens_at date or due_at date')
    false
  end

  def populate_placeholders(core_completion_time: Time.now)
    personalized_placeholder_task_steps = personalized_task_steps.select{|task_step| task_step.placeholder?}
    return if personalized_placeholder_task_steps.none?

    num_placeholders = personalized_placeholder_task_steps.count

    taskee = taskings.first.role

    homework_history = get_taskee_homework_history(task: self, taskee: taskee)

    exercise_history = get_exercise_history(tasks: homework_history)

    exercise_pools = get_exercise_pools(tasks: homework_history)

    exercise_uids = OpenStax::BigLearn::V1.get_projection_exercises(
      role:              taskee,
      tag_search:        biglearn_condition([exercise_pools.first]),
      count:             num_placeholders,
      difficulty:        0.5,
      allow_repetitions: true
    )
    exercise_urls = exercise_uids.collect{|uid| "http://exercises.openstax.org/exercises/#{uid}"}
    chosen_exercises = SearchLocalExercises[url: exercise_urls, match_count: 1]
    raise "could not fill all placeholder slots (expected #{num_placeholders} exercises, got #{chosen_exercises.count})" \
      unless chosen_exercises.count == num_placeholders

    chosen_exercise_task_step_pairs = chosen_exercises.zip(personalized_placeholder_task_steps)
    chosen_exercise_task_step_pairs.each do |exercise, step|
      step.tasked.destroy!
      tasked_exercise = TaskExercise[task_step: step, exercise: exercise]
      step.personalized_group!
      # inject_debug_content!(step.tasked, "This exercise is part of the #{step.group_type}")
    end

    self.save!
    self
  end

  def get_taskee_homework_history(task:, taskee:)
    tasks = Tasks::Models::Task.joins{taskings}.
                                where{taskings.entity_role_id == taskee.id}

    homework_history = tasks.
                         select{|tt| tt.homework?}.
                         reject{|tt| tt == task}.
                         sort_by{|tt| tt.due_at}.
                         push(task).
                         reverse

    homework_history
  end

  def get_exercise_history(tasks:)
    exercise_history = tasks.collect do |task|
      exercise_steps = task.task_steps.select{|task_step| task_step.exercise?}
      content_exercises = exercise_steps.collect do |ex_step|
        content_exercise = Content::Models::Exercise.where{url == ex_step.tasked.url}
      end
      content_exercises
    end.flatten.compact
    exercise_history
  end

  def get_exercise_pools(tasks:)
    exercise_pools = tasks.collect do |task|
      urls = task.task_steps.select{|task_step| task_step.exercise?}.
                             collect{|task_step| task_step.tasked.url}.
                             uniq

      exercise_los = Content::Models::Tag.joins{exercise_tags.exercise}
                                         .where{exercise_tags.exercise.url.in urls}
                                         .select{|tag| tag.lo?}
                                         .collect{|tag| tag.value}

      pages          = Content::Routines::SearchPages[tag: exercise_los, match_count: 1]
      page_los       = Content::GetLos[page_ids: pages.map(&:id)]
      page_exercises = Content::Routines::SearchExercises[tag: page_los, match_count: 1]

      review_exercises = Content::Models::Exercise.joins{exercise_tags.tag}
                                                  .where{exercise_tags.tag.value.eq 'ost-chapter-review'}
                                                  .where{id.in page_exercises.map(&:id)}

      exercises = Content::Models::Exercise.joins{exercise_tags.tag}
                                           .where{exercise_tags.tag.value.in ['concept', 'problem']}
                                           .where{id.in review_exercises.map(&:id)}

      exercises
    end
    exercise_pools
  end

  def biglearn_condition(exercise_pools)
    urls = exercise_pools.flatten.map(&:url).uniq

    los = Content::Models::Tag.joins{exercise_tags.exercise}
                              .where{exercise_tags.exercise.url.in urls}
                              .select{|tag| tag.lo?}
                              .collect{|tag| tag.value}
                              .uniq

    condition = {
      _and: [
        {
          _and: [
            'ost-chapter-review',
            {
              _or: [
                'concept',
                'problem'
              ]
            }
          ]
        },
        {
          _or: los
        }
      ]
    }

    condition
  end

end
