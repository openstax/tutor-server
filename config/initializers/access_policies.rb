require './app/subsystems/user_profile/models/profile'

OSU::AccessPolicy.register(UserProfile::Models::Profile, UserAccessPolicy)
OSU::AccessPolicy.register(Entity::Models::Task, TaskAccessPolicy)
OSU::AccessPolicy.register(Entity::Models::TaskPlan, TaskPlanAccessPolicy)
OSU::AccessPolicy.register(Tasks::Models::TaskedExercise, TaskedAccessPolicy)
OSU::AccessPolicy.register(Tasks::Models::TaskedReading, TaskedAccessPolicy)
OSU::AccessPolicy.register(Tasks::Models::TaskedVideo, TaskedAccessPolicy)
OSU::AccessPolicy.register(Entity::Models::Course, CourseAccessPolicy)
