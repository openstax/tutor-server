require 'tutor/subsystems'

# Include extensions into ActiveRecord::Base so they're available to all models
ActiveRecord::Base.send(:include, Tutor::SubSystems::AssociationExtensions)

#======================
# Initialize SubSystems
#======================
Tutor::SubSystems.configure(
  path: Rails.root.join("app/subsystems"),
  limit_to: %w(content course_content course_profile entity tasks role course_membership)
)
