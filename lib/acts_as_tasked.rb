module ActsAsTasked

  def self.included(base)
    base.extend(ClassMethods)
  end

  module ClassMethods
    def acts_as_tasked
      class_exec do
        acts_as_paranoid

        has_one :task_step, -> { with_deleted }, as: :tasked, inverse_of: :tasked

        after_update :touch_task_step

        delegate :first_completed_at, :last_completed_at, :completed?, :complete,
                 :can_be_recovered?, to: :task_step, allow_nil: true

        def touch_task_step
          task_step.touch if task_step.try(:persisted?)
        end

        def has_correctness?
          false
        end

        def has_content?
          false
        end

        def exercise?
          false
        end

        def placeholder?
          false
        end

        def los
          []
        end

        def aplos
          []
        end
      end
    end
  end

end

ActiveRecord::Base.send :include, ActsAsTasked
