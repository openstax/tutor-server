module Admin
  class SalesforceController < BaseController
    def failures
      terms = CourseProfile::Models::Course.terms.values_at :spring, :summer, :fall, :winter

      @courses = CourseProfile::Models::Course
        .not_ended
        .where(is_test: false, is_preview: false, is_excluded_from_salesforce: false, term: terms)
        .where.not(
          CourseMembership::Models::Teacher.joins(role: { profile: :account }).where(
            <<~WHERE_SQL
              "course_membership_teachers"."course_profile_course_id" =
                "course_profile_courses"."id"
            WHERE_SQL
          ).where.not(role: { profile: { account: { salesforce_contact_id: nil } } }).arel.exists
        ).order(:id).preload(:students, teachers: { role: { profile: :account } })
    end
  end
end
