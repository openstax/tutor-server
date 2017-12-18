# Generates SQL that can be used on a join with a values table, like so:
# INNER JOIN (#{ValuesTable.new(values_array)}) AS "values" ("first_value", "second_value")
#   ON "table"."first_value" = "values"."first_value"
#     AND "table"."second_value" = "values"."second_value"
class ValuesTable
  UUID_REGEX = /\A[0-9A-F]{8}-[0-9A-F]{4}-4[0-9A-F]{3}-[89AB][0-9A-F]{3}-[0-9A-F]{12}\z/i

  attr_reader :values_array

  # values_array is an array of arrays
  # Each array entry becomes a row in the values table
  def initialize(values_array)
    @values_array = values_array
  end

  def to_sql
    raise 'ValuesTable cannot be given an empty array' if values_array.empty?

    "VALUES #{values_array.map do |values|
      raise 'ValuesTable cannot be given an array containing empty arrays' if values.empty?
      next if values.any? { |value| value.is_a?(Array) && value.empty? }
      "(#{values.map { |value| sanitize value }.join(', ')})"
    end.compact.join(', ')}"
  end

  def to_s
    to_sql
  end

  protected

  def sanitize(value)
    return "ARRAY[#{value.map { |val| sanitize val }.join(', ')}]" if value.is_a?(Array)

    sanitized_value = ActiveRecord::Base.sanitize value

    UUID_REGEX === value ? "#{sanitized_value}::uuid" : sanitized_value
  end
end
