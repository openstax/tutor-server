class Research::Models::Manipulation < ApplicationRecord

  class RecordingPreferenceNotSpecified < RuntimeError
  end

  belongs_to :study_brain, inverse_of: :manipulations
  belongs_to :cohort
  belongs_to :study

  belongs_to :target, polymorphic: true

  validate :ensure_should_record

  def ignore!
    @should_record = false
  end

  def record!
    @should_record = true
  end

  def should_record?
    !!@should_record
  end

  def explode_if_unmarked
    if @should_record.nil?
      raise RecordingPreferenceNotSpecified, "study brain must call ignore! or record! on manipulation"
    end
  end

  protected

  def ensure_should_record
    errors.add(:base, 'cannot save unless record! has been called') unless should_record?
  end

end
