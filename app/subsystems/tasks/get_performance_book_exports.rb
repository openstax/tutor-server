module Tasks
  class GetPerformanceBookExports
    lev_routine express_output: :exports

    protected
    def exec(course:, role:)
      exports = Models::PerformanceBookExport.where(course: course, role: role)
      outputs[:exports] = exports.collect do |export|
        {
          filename: "#{export.filename}.#{extension}",
          url: "/something/here/#{export.filename}.#{extension}",
          created_at: export.created_at
        }
      end
    end

    private
    def extension
      'xlsx'
    end
  end
end
