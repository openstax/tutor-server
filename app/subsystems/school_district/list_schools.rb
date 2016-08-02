module SchoolDistrict
  class ListSchools
    lev_routine express_output: :schools

    protected

    def exec
      outputs.schools = ::SchoolDistrict::Models::School.all
    end
  end
end
