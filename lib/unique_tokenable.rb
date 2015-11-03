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
      before_validation -> { generate_unique_token(token_field, options) }
      validates token_field, uniqueness: true
    end

    def unique_token_mode
      @unique_token_mode
    end
  end

  private
  def generate_unique_token(field, options)
    return unless send(field).blank?

    generator = TokenGenerator.generator_for(self.class.unique_token_mode)

    begin
      self[field] = generator.generate_with(self.class.unique_token_mode)
    end while self.class.exists?(field => self[field])
  end
end

ActiveRecord::Base.class_eval do
  include UniqueTokenable
end
