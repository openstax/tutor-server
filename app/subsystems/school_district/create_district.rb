module SchoolDistrict
  class CreateDistrict
    lev_routine express_output: :district

    protected
    def exec(name:)
      district = Models::District.create!(name: name)

      outputs[:district] = {
        id: district.id,
        name: district.name
      }
    end
  end
end
