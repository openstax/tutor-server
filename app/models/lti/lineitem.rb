class Lti::Lineitem
  include ActiveModel::Model
  include ActiveModel::Dirty

  attr_accessor :id, :startDateTime, :endDateTime, :scoreMaximum,
                :label, :tag, :resourceId, :resourceLinkId

  def persisted?
    !id.blank?
  end

  def save
    return false unless valid?

    # TODO: API call

    changes_applied

    true
  end

  def save!
    raise(ActiveRecord::RecordNotSaved.new('Failed to save the record', self)) unless save
  end
end
