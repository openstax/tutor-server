module Api::V1
  RailsCollectionSetter = ->(input:, represented:, binding:, **) do
    collection = represented.send(binding.getter)

    # Hard-delete records that are being replaced
    # Any further dependent records must be handled with foreign key constraints
    collection.delete_all :delete_all

    # Don't use the collection= method (setter) so we can return meaningful errors
    input.each { |record| collection << record }
  end
end
