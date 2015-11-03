require 'generate_token/token_generator'
require 'generate_token/secure_random_token_generator'
require 'generate_token/babbler_token_generator'

module UniqueTokenable
  def self.included(base)
    base.extend ClassMethods
  end

  module ClassMethods
    def unique_token(token_field, options = {})
      @unique_token_mode = options[:mode] ||= :hex
      before_validation -> { generate_unique_token(self, token_field, options) }
      validates token_field, uniqueness: true
    end

    def unique_token_mode
      @unique_token_mode
    end
  end

  private
  def generate_unique_token(record, field, options)
    return unless record.send(field).blank?

    generator = TokenGenerator.generator_for(record.class.unique_token_mode)

    begin
      record[field] = generator.generate_with(record.class.unique_token_mode)
    end while record.class.exists?(field => record[field])
  end
end

ActiveRecord::Base.class_eval do
  include UniqueTokenable
end
