class Research::Models::StudyBrain < ApplicationRecord
  belongs_to :cohort, inverse_of: :study_brains

  validates :name, :type, :code, presence: true

  scope :active, -> { joins(:cohort).merge(Research::Models::Cohort.active) }
  scope :student_task, -> {
    where(type: [
            'Research::Models::DisplayStudentTask',
            'Research::Models::UpdateStudentTasked'
          ])
  }
  def type_identifier
    @type_identifier ||= self.class.to_s.demodulize.underscore.to_sym
  end

  def should_execute?(desired_type)
    cohort.study.active? && type_identifier == desired_type
  end

  # Note!  This only creates the "apply" method after the brain is
  # retrieved from the database.  It's safe to do so because that's
  # the only way they're called. If we later decide to create and execute
  # a brain immediately, we'll need to add a after_initialize block
  after_find do |brain|
    brain.add_instance_method
  end

end
