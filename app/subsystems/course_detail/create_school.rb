module CourseDetail
  class CreateSchool
    lev_routine express_output: :school

    protected
    def exec(name:, district: nil)
      district ||= NoDistrict.new
      outputs.school = Models::School.create(name: name,
                                             course_detail_district_id: district.id)
    end

    class NoDistrict
      def id; end
    end
  end
end
