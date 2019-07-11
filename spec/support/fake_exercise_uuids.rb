# Assign a random uuid and group_uuid if those don't exist
# when the Content::Models::Exercise are created
# So we don't have to re-record all of our old cassettes
# The data used to create them is most likely long gone

module FakeExerciseUuids
  def initialize(attributes = nil, &block)
    attributes = {} if attributes.nil?

    attributes[:uuid] ||= SecureRandom.uuid
    attributes[:group_uuid] ||= SecureRandom.uuid

    super(attributes, &block)
  end
end

# We need both of these because this file runs after the initial run of to_prepare blocks
ActiveSupport::Reloader.to_prepare { Content::Models::Exercise.send :include, FakeExerciseUuids }
Content::Models::Exercise.send :include, FakeExerciseUuids
