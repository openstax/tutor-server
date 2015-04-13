module ActsAsTasked

  def self.included(base)
    base.extend(ClassMethods)
  end

  module ClassMethods
    def acts_as_tasked
      class_eval do
        has_one :task_step, as: :tasked, inverse_of: :tasked

        delegate :completed_at, :completed?, :complete, to: :task_step, allow_nil: true

        def can_be_recovered?
          false
        end
      end
    end
  end

end

ActiveRecord::Base.send :include, ActsAsTasked
