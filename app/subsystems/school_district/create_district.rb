module SchoolDistrict
  class CreateDistrict
    lev_routine outputs: { district: :_self }

    protected
    def exec(name:)
      district = Models::District.create!(name: name)

      set(district: { id: district.id, name: district.name })
    end
  end
end
