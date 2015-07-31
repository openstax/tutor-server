require './app/subsystems/user_profile/models/profile'

OSU::AccessPolicy.register(UserProfile::Models::Profile, UserAccessPolicy)
OSU::AccessPolicy.register(Tasks::Models::Task, TaskAccessPolicy)
OSU::AccessPolicy.register(Tasks::Models::TaskPlan, TaskPlanAccessPolicy)
OSU::AccessPolicy.register(Tasks::Models::TaskedExercise, TaskedAccessPolicy)
OSU::AccessPolicy.register(Tasks::Models::TaskedReading, TaskedAccessPolicy)
OSU::AccessPolicy.register(Tasks::Models::TaskedVideo, TaskedAccessPolicy)
OSU::AccessPolicy.register(Tasks::Models::TaskedInteractive, TaskedAccessPolicy)
OSU::AccessPolicy.register(Tasks::Models::TaskedPlaceholder, TaskedAccessPolicy)
OSU::AccessPolicy.register(Tasks::Models::TaskedExternalUrl, TaskedAccessPolicy)
OSU::AccessPolicy.register(Entity::Course, CourseAccessPolicy)
OSU::AccessPolicy.register(CourseMembership::Models::Student, StudentAccessPolicy)
OSU::AccessPolicy.register(Lev::BackgroundJob, JobAccessPolicy)
