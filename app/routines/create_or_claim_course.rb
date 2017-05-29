class CreateOrClaimCourse

  lev_routine express_output: :course

  uses_routine CreateCourse, as: :create_course,
               translations: { outputs: { type: :verbatim } }


  uses_routine CourseProfile::ClaimPreviewCourse,  as: :claim_preview_course,
               translations: { outputs: { type: :verbatim } }

  uses_routine AddUserAsCourseTeacher, as: :add_user_as_teacher,
               translations: { outputs: { type: :verbatim } }

  def exec(attributes)
    if attributes[:is_preview]
      run(:claim_preview_course, {
            name: attributes[:name],
            catalog_offering: attributes[:catalog_offering]
      })
    else
      run(:create_course, attributes)
    end
    run(:add_user_as_teacher, course: outputs.course, user: attributes[:teacher]) if errors.none?
  end


end
