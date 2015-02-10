module BelongsToResource

  def self.included(base)
    base.extend(ClassMethods)
  end
  
  module ClassMethods
    def belongs_to_resource
      class_eval do
        belongs_to :resource, dependent: :destroy

        validates :resource, presence: true, uniqueness: true

        delegate :url, :content, to: :resource
      end
    end
  end

end

ActiveRecord::Base.send :include, BelongsToResource
