require 'tutor/subsystems'

# Manually require Entity::Role
# require_dependency makes it play nice with autoload, reload and eager_load
# Rails's autoload fails because this has the same name as the
# top level subsystem module Role (from the Role subsystem)
# Ruby's autoload finds the toplevel Role module and doesn't even call Rails's autoload
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
)
