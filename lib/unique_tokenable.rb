require 'generate_token/token_generator'
require 'generate_token/secure_random_token_generator'
require 'generate_token/babbler_token_generator'

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
    mode = options[:mode] || :hex

    begin
      record[field] = TokenGenerator.generator_for(mode).generate_with(mode)
    end while record.class.exists?(field => record[field])
  end
end

ActiveRecord::Base.class_eval do
  include UniqueTokenable
end
