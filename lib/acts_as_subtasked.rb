module ActsAsSubtasked

  def self.included(base)
    base.extend(ClassMethods)
  end
  
  module ClassMethods
    def acts_as_subtasked
      class_eval do
        has_one :exercise_substep, as: :subtasked, dependent: :destroy

        validates :exercise_substep, presence: true

        delegate :completed_at, :completed?, :complete, to: :exercise_substep
      end
    end
  end

end

ActiveRecord::Base.send :include, ActsAsSubtasked
