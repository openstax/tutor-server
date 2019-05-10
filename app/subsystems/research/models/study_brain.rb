class Research::Models::StudyBrain < ApplicationRecord
  belongs_to :study, inverse_of: :study_brains

  has_many :manipulations, inverse_of: :study_brain

  validates :name, :type, :code, presence: true
  validate :no_update_when_study_active

  scope :active, -> { joins(:study).merge(Research::Models::Study.active) }
  scope :student_task, -> {
    where(type: [
            'Research::Models::ModifiedTask',
            'Research::Models::ModifiedTasked'
          ])
  }
  def type_identifier
    @type_identifier ||= self.class.to_s.demodulize.underscore.to_sym
  end

  def should_execute?(desired_type)
    study.active? && type_identifier == desired_type
  end

  # Note!  This only creates the dynamic methods after the brain is
  # retrieved from the database.  It's safe to do so because that's
  # the only way they're called. If we later decide to create and execute
  # a brain immediately, we'll need to add a after_initialize block
  after_find do |brain|
    brain.add_instance_method
  end

  protected

  def with_manipulation(cohort:, target:)
    manipulation = manipulations.build(cohort: cohort, study: cohort.study, target: target)
    yield manipulation
  rescue => e
    manipulation.ignore!
    Raven.capture_message("Exception #{e}, study brain code: #{code}")
    raise
  ensure # note: we aren't rescuing anything but we need to ensure manipulation gets saved
    manipulation.explode_if_unmarked
    manipulation.save! if manipulation.should_record?
  end


  def no_update_when_study_active
    return unless study.active?

    errors.add(:base, "can't be saved when study is active")
    throw :abort
  end

end
