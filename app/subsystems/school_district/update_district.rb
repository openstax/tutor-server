module SchoolDistrict
  class UpdateDistrict
    lev_routine express_output: :district

    protected

    def exec(district:, name:)
      district.update_attributes(name: name)

      transfer_errors_from(district, {type: :verbatim})

      outputs.district = district
    end
  end
end
