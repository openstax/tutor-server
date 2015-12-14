module SchoolDistrict
  class ListSchools
    lev_routine outputs: { schools: :_self }

    protected
    def exec
      schools = Models::School.all
      set(schools: schools.collect do |school|
        { id: school.id,
          name: school.name,
          district_name: school.district_name }
      end)
    end
  end
end
