# Assign a random uuid and group_uuid if those don't exist
# when the Content::Models::Exercise are created
# So we don't have to re-record all of our old cassettes
# The data used to create them is most likely long gone

module FakeExerciseUuids
  def initialize(attributes = nil, options = {})
    attributes ||= {}
    attributes[:uuid] ||= SecureRandom.uuid
    attributes[:group_uuid] ||= SecureRandom.uuid

    super(attributes, options)
  end
end

Content::Models::Exercise.send :include, FakeExerciseUuids
