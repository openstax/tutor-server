module SchoolDistrict
  class CreateSchool
    lev_routine express_output: :school

    protected
    def exec(name:, district: nil)
      district ||= NoDistrict.new
      outputs.school = Models::School.create(name: name,
                                             school_district_district_id: district.id)

      # AddTermableToGroup[termable: outputs.school, group: district]
    end

    class NoDistrict
      def id; end
    end
  end
end
