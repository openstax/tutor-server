module ActsAsTasked

  def self.included(base)
    base.extend(ClassMethods)
  end

  module ClassMethods
    def acts_as_tasked
      class_eval do
        has_one :task_step, as: :tasked, dependent: :destroy

        validates :task_step, presence: true

        delegate :completed_at, :completed?, :complete, to: :task_step
      end
    end
  end

end

ActiveRecord::Base.send :include, ActsAsTasked
