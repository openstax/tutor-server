require 'tutor/subsystems'

# Manually require Entity::Role
# require_dependency makes it play nice with autoload, reload and eager_load
# Ruby's autoload finds the toplevel Role module and refuses to call const_missing,
# even if you specify Entity::Role or ::Entity::Role, which causes Rails's autoload to never trigger
require_dependency './app/models/entity/role'

# Only these namespaces have been configured and should be extended
# Once they are all configured, we can remove this line entirely,
# but will still need to require the subsystems on rails boot, before any models are loaded
Tutor::SubSystems.valid_namespaces = %w(
  content
  course_content
  course_profile
  entity
  tasks
  role
  course_membership
  school_district
  legal
  user
  catalog
  salesforce
)
