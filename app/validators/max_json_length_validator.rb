class MaxJsonLengthValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    if record[attribute].to_s.length > options[:with]
      record.errors[attribute] << (options[:message] || 'is too long')
    end
  end
end
