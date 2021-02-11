OSU::AccessPolicy.register(User::Models::Profile, UserAccessPolicy)
OSU::AccessPolicy.register(Tasks::Models::GradingTemplate, GradingTemplateAccessPolicy)
OSU::AccessPolicy.register(Tasks::Models::Task, TaskAccessPolicy)
OSU::AccessPolicy.register(Tasks::Models::TaskPlan, TaskPlanAccessPolicy)
OSU::AccessPolicy.register(Tasks::Models::TaskingPlan, TaskingPlanAccessPolicy)
OSU::AccessPolicy.register(Tasks::Models::TaskedExercise, TaskedAccessPolicy)
OSU::AccessPolicy.register(Tasks::Models::TaskedReading, TaskedAccessPolicy)
OSU::AccessPolicy.register(Tasks::Models::TaskedVideo, TaskedAccessPolicy)
OSU::AccessPolicy.register(Tasks::Models::TaskedInteractive, TaskedAccessPolicy)
OSU::AccessPolicy.register(Tasks::Models::TaskedPlaceholder, TaskedAccessPolicy)
OSU::AccessPolicy.register(Tasks::Models::TaskedExternalUrl, TaskedAccessPolicy)
OSU::AccessPolicy.register(Tasks::Models::PracticeQuestion, PracticeQuestionAccessPolicy)
OSU::AccessPolicy.register(CourseProfile::Models::Course, CourseAccessPolicy)
OSU::AccessPolicy.register(CourseMembership::Models::Student, StudentAccessPolicy)
OSU::AccessPolicy.register(CourseMembership::Models::Teacher, TeacherAccessPolicy)
OSU::AccessPolicy.register(CourseMembership::Models::TeacherStudent, TeacherStudentAccessPolicy)
OSU::AccessPolicy.register(Content::Models::Exercise, ExerciseAccessPolicy)
OSU::AccessPolicy.register(Content::Models::Ecosystem, EcosystemAccessPolicy)
OSU::AccessPolicy.register(Content::Models::Note, NoteAccessPolicy)
OSU::AccessPolicy.register(Jobba::Status, JobAccessPolicy)
OSU::AccessPolicy.register(CourseMembership::Models::Period, PeriodAccessPolicy)
OSU::AccessPolicy.register(CourseMembership::Models::EnrollmentChange, EnrollmentChangeAccessPolicy)
OSU::AccessPolicy.register(Tasks::Models::ConceptCoachTask, Cc::TaskAccessPolicy)
OSU::AccessPolicy.register(Catalog::Models::Offering, OfferingAccessPolicy)
OSU::AccessPolicy.register(TrackTutorOnboardingEvent, TrackTutorOnboardingEventPolicy)
OSU::AccessPolicy.register(OpenStax::Payments::FakePurchasedItem, AllowAllAccessPolicy)
OSU::AccessPolicy.register(Research::Models::Survey, ResearchSurveyAccessPolicy)
OSU::AccessPolicy.register(Entity::Role, RoleAccessPolicy)
OSU::AccessPolicy.register(User::Models::Suggestion, SuggestionAccessPolicy)
