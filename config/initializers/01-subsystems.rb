require 'tutor/subsystems'

# Manually require entity/role
# If it's not required first, it will conflict when files are loaded from the Role subsystem
require 'entity/role'

# Only these namespaces have been configured and should be extended
# Once they are all configured, we can remove this line entirely,
# but will still need to require the subsystems on rails boot, before any models are loaded
Tutor::SubSystems.valid_namespaces = %w(content course_content course_profile entity tasks role course_membership)
