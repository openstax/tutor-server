class Role::User < ActiveRecord::Base
  ## using class_name as workaround, see: https://github.com/rails/rails/issues/15811
  belongs_to :entity_user, class_name: "::Entity::User"
  belongs_to :entity_role, class_name: "::Entity::Role"

  validates_presence_of :entity_user_id
  validates_presence_of :entity_role_id
end
