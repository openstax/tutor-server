class Lti::Score
  include ActiveModel::Model
  include ActiveModel::Dirty

  API_WRITE_ATTRIBUTES = [
    :userId, :scoreGiven, :scoreMaximum, :comment, :timestamp, :activityProgress, :gradingProgress
  ]
  ATTRIBUTES = [ :lineitem ] + API_WRITE_ATTRIBUTES

  validates :lineitem, :userId, :timestamp, :activityProgress, :gradingProgress, presence: true

  define_attribute_methods *ATTRIBUTES
  attr_reader *ATTRIBUTES

  ATTRIBUTES.each do |attribute|
    variable = "@#{attribute}".to_sym

    define_method("#{attribute}=") do |value|
      public_send "#{attribute}_will_change!" unless value == instance_variable_get(variable)
      instance_variable_set variable, value
    end
  end

  def persisted?
    false
  end

  def url
    "#{lineitem.url}/scores"
  end

  def save
    return false unless valid?

    body = {}
    API_WRITE_ATTRIBUTES.each do |attribute|
      value = public_send attribute
      next if value.blank?

      body[attribute] = value
    end

    lineitem.resource_link.access_token.post(
      url, headers: { 'Content-Type': 'application/vnd.ims.lis.v1.score+json' }, body: body.to_json
    )

    changes_applied

    true
  end

  def save!
    raise(ActiveRecord::RecordNotSaved.new('Failed to save the record', self)) unless save
  end
end
