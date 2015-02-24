class RoleSs::UserRoleMap < ActiveRecord::Base
  ## using class_name as bug workaround, see: https://github.com/rails/rails/issues/15811
  belongs_to :entity_ss_user, class_name: "::EntitySs::User"
  belongs_to :entity_ss_role, class_name: "::EntitySs::Role"

  validates_presence_of :entity_ss_user_id
  validates_presence_of :entity_ss_role_id
end
