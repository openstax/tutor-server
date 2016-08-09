module SchoolDistrict
  class CreateDistrict
    lev_routine express_output: :district

    protected

    def exec(name:)
      outputs.district = ::SchoolDistrict::Models::District.create(name: name)

      transfer_errors_from(outputs.district, {type: :verbatim})
    end
  end
end
