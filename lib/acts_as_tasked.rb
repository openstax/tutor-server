module ActsAsTasked

  def self.included(base)
    base.extend(ClassMethods)
  end

  module ClassMethods
    def acts_as_tasked
      class_eval do
        has_one :task_step, as: :tasked, inverse_of: :tasked

        after_update { task_step.try(:touch) if task_step.try(:persisted?) }

        delegate :first_completed_at, :last_completed_at, :completed?, :complete,
          to: :task_step,
          allow_nil: true

        def can_be_recovered?
          false
        end

        def exercise?
          false
        end

        def placeholder?
          false
        end

        def has_correctness?
          false
        end

        def los
          []
        end
      end
    end
  end

end

ActiveRecord::Base.send :include, ActsAsTasked
