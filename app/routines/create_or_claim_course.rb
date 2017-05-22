class CreateOrClaimCourse

  lev_routine express_output: :course

  uses_routine CreateCourse, translations: { outputs: { type: :verbatim } },
               as: :create_course

  uses_routine CourseProfile::ClaimPreviewCourse, translations: { outputs: { type: :verbatim } },
               as: :claim_preview_course


  def exec(attributes)
    if attributes[:is_preview]
      run(:claim_preview_course, {
            name: attributes[:name],
            catalog_offering: attributes[:catalog_offering]
      })
    else
      run(:create_course, attributes)
    end
  end


end
