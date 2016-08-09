module SchoolDistrict
  class DeleteSchool
    lev_routine

    protected

    def exec(school:)
      if school.destroy
        Legal::ForgetAbout[item: school]
      else
        fatal_error code: :school_has_courses,
                    message: 'Cannot delete a school that has courses.'
      end
    end
  end
end
