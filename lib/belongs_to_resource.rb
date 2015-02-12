module BelongsToResource

  def self.included(base)
    base.extend(ClassMethods)
  end
  
  module ClassMethods
    def belongs_to_resource(options = {})
      class_eval do
        belongs_to :resource, dependent: :destroy

        validates :resource, presence: true unless options[:allow_nil]
        validates :resource, uniqueness: true, allow_nil: options[:allow_nil]

        delegate :url, :content, :topics, to: :resource,
                 allow_nil: options[:allow_nil]
      end
    end
  end

end

ActiveRecord::Base.send :include, BelongsToResource
