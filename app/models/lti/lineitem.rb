class Lti::Lineitem
  include ActiveModel::Model
  include ActiveModel::Dirty

  API_WRITE_ATTRIBUTES = [
    :startDateTime, :endDateTime, :scoreMaximum, :label, :tag, :resourceId, :resourceLinkId
  ]
  ATTRIBUTES = [ :id, :resource_link ] + API_WRITE_ATTRIBUTES

  validates :resource_link, :scoreMaximum, :label, presence: true

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
    !id.blank?
  end

  def resourceLinkId
    return @resourceLinkId unless @resourceLinkId.blank?

    resource_link.resource_link_id unless resource_link.resource_is_course?
  end

  def url
    persisted? ? id : resource_link.lineitems_endpoint
  end

  def save
    return true if persisted? && !changed?
    return false unless valid?

    verb = persisted? ? :put : :post

    body = {}
    API_WRITE_ATTRIBUTES.each do |attribute|
      value = public_send attribute
      next if value.blank?

      body[attribute] = value
    end

    response = resource_link.access_token.request(
      verb,
      url,
      headers: { 'Content-Type': 'application/vnd.ims.lis.v2.lineitem+json' },
      body: body.to_json
    )
    self.id = JSON.parse(response.body)['id']

    changes_applied

    true
  end

  def save!
    raise(ActiveRecord::RecordNotSaved.new('Failed to save the record', self)) unless save
  end

  def destroy
    return false unless persisted?

    resource_link.access_token.delete url
    id = nil

    true
  end
  alias_method :delete, :destroy
  alias_method :destroy!, :destroy
  alias_method :delete!, :destroy!
end
