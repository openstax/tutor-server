# Uniqueness validations use 1 query per validation per record when creating or updating records
# Set record.skip_uniqueness_validations = true on each record
# to skip uniqueness validations during bulk operations
# Make sure you have the corresponding unique indices/constraints in the database
# (you should have them anyway since Rails uniqueness validations are subject to race conditions)
ActiveRecord::Base.class_exec do
  attr_accessor :skip_uniqueness_validations
end

ActiveRecord::Validations::UniquenessValidator.class_exec do
  def validate_each_with_skip(record, attribute, value)
    validate_each_without_skip(record, attribute, value) unless record.skip_uniqueness_validations
  end

  alias_method_chain :validate_each, :skip
end
