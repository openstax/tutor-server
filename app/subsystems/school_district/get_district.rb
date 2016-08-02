module SchoolDistrict
  class GetDistrict
    lev_routine express_output: :district

    protected

    def exec(id:)
      outputs.district = ::SchoolDistrict::Models::District.find_by(id: id)
    end
  end
end
