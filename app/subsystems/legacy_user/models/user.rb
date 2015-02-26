class LegacyUser::User < ActiveRecord::Base
  ## using class_name as workaround, see: https://github.com/rails/rails/issues/15811
  belongs_to :user
  belongs_to :entity_user, class_name: "::Entity::User"

  validates_presence_of :user_id
  validates_presence_of :entity_user_id
end
