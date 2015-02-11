class Interactive < ActiveRecord::Base
  belongs_to_resource

  has_many :interactive_topics, dependent: :destroy
end
