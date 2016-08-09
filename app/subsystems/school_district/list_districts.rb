module SchoolDistrict
  class ListDistricts
    lev_routine express_output: :districts

    protected

    def exec
      outputs.districts = ::SchoolDistrict::Models::District.all
    end
  end
end
