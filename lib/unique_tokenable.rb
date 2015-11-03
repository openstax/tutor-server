require 'generate_token'

module UniqueTokenable
  def self.included(base)
    base.extend ClassMethods
  end

  module ClassMethods
    def unique_token(token_field, options = {})
      before_validation -> { generate_unique_token(self, token_field, options) }
    end
  end

  private
  def generate_unique_token(record, field, options)
    GenerateToken.apply(record: record, attribute: field, mode: options[:mode])
  end
end
