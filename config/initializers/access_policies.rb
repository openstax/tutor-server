require './app/subsystems/user_profile/models/profile'

OSU::AccessPolicy.register(UserProfile::Models::Profile, UserAccessPolicy)
OSU::AccessPolicy.register(Task, TaskAccessPolicy)
OSU::AccessPolicy.register(TaskPlan, TaskPlanAccessPolicy)
OSU::AccessPolicy.register(TaskedExercise, TaskedAccessPolicy)
OSU::AccessPolicy.register(TaskedReading, TaskedAccessPolicy)
OSU::AccessPolicy.register(TaskedVideo, TaskedAccessPolicy)
OSU::AccessPolicy.register(Entity::Models::Course, CourseAccessPolicy)
