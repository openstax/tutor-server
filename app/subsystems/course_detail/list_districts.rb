module CourseDetail
  class ListDistricts
    lev_routine express_output: :districts

    protected
    def exec
      districts = Models::District.all
      outputs.districts = districts.collect do |district|
        {
          id: district.id,
          name: district.name
        }
      end
    end
  end
end
