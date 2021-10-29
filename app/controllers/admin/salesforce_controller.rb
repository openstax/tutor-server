module Admin
  class SalesforceController < BaseController
    def failures
      terms = CourseProfile::Models::Course.terms.values_at(
        :spring, :summer, :fall, :winter, :preview
      )

      @courses = CourseProfile::Models::Course
        .not_ended
        .where(is_test: false, is_preview: false, is_excluded_from_salesforce: false, term: terms)
        .where(
          <<~WHERE_SQL
            (
              EXISTS (
                SELECT *
                FROM "course_membership_teachers"
                WHERE "course_membership_teachers"."course_profile_course_id" =
                        "course_profile_courses"."id" AND
                      "course_membership_teachers"."deleted_at" IS NULL
              ) OR EXISTS (
                SELECT *
                FROM "course_membership_students"
                WHERE "course_membership_students"."course_profile_course_id" =
                        "course_profile_courses"."id" AND
                      "course_membership_students"."dropped_at" IS NULL
              )
            ) AND NOT EXISTS (
              SELECT *
              FROM "course_membership_teachers"
              INNER JOIN "entity_roles"
                ON "entity_roles"."id" = "course_membership_teachers"."entity_role_id"
              INNER JOIN "user_profiles"
                ON "user_profiles"."id" = "entity_roles"."user_profile_id"
              INNER JOIN "openstax_accounts_accounts"
                ON "openstax_accounts_accounts"."id" = "user_profiles"."account_id"
              WHERE "course_membership_teachers"."course_profile_course_id" =
                      "course_profile_courses"."id" AND
                    "openstax_accounts_accounts"."salesforce_contact_id" IS NOT NULL
            )
          WHERE_SQL
        ).preload(:students, teachers: { role: { profile: :account } })
    end
  end
end
