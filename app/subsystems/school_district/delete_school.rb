module SchoolDistrict
  class DeleteSchool
    lev_routine

    protected
    def exec(id:)
      school = Models::School.find(id)
      school.destroy
      transfer_errors_from(school, {type: :verbatim}, true)

      # TODO find a more appropriate home for this
      Legal::ForgetAboutContracts[with_respect_to: school]
    end
  end
end
