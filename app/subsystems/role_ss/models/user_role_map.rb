class RoleSs::UserRoleMap < ActiveRecord::Base
  belongs_to :entity_ss_user
  belongs_to :entity_ss_role

  validates_presence_of :entity_ss_user_id
  validates_presence_of :entity_ss_role_id
end
