module HasOneExerciseStep

  def self.included(base)
    base.extend(ClassMethods)
  end
  
  module ClassMethods
    def has_one_exercise_step
      class_eval do
        has_one :exercise_step, as: :step, dependent: :destroy

        validates :exercise_step, presence: true

        delegate :completed_at, :completed?, :complete, to: :exercise_step
      end
    end
  end

end

ActiveRecord::Base.send :include, HasOneExerciseStep
