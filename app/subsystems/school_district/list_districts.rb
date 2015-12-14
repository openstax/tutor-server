module SchoolDistrict
  class ListDistricts
    lev_routine outputs: { districts: :_self }

    protected
    def exec
      districts = Models::District.all
      set(districts: districts.collect do |district|
        {
          id: district.id,
          gid: district.to_global_id.to_s,
          name: district.name
        }
      end)
    end
  end
end
