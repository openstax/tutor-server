module UniqueTokenable
  def self.included(base)
    base.extend ClassMethods
  end

  module ClassMethods
    def unique_token(token_field, options = {})
      options[:mode] ||= :hex
      before_validation -> { generate_unique_token(token_field, options) }, prepend: true
      validates token_field, presence: true, uniqueness: true
    end
  end

  protected

  def generate_unique_token(field, options)
    return unless self[field].blank?

    begin
      self[field] = SecureRandomTokenGenerator[options]
    end while self.class.unscoped.exists?(field => self[field])
  end
end

ActiveRecord::Base.send :include, UniqueTokenable
