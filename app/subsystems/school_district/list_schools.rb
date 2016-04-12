module SchoolDistrict
  class ListSchools
    lev_routine express_output: :schools

    protected
    def exec
      schools = Models::School.all
      outputs.schools = schools.map do |school|
        { id: school.id,
          name: school.name,
          district_name: school.district_name }
      end
    end
  end
end
