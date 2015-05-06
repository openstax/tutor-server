module Tasks
  class ExportPerformanceBook
    lev_routine

    uses_routine GetCourseProfile,
      translations: { outputs: { type: :verbatim } },
      as: :get_course_profile

    protected
    def exec(role:, course:)
      run(:get_course_profile, course: course)

      file = Axlsx::Package.new
      workbook = file.workbook

      create_summary_worksheet(workbook: workbook, course: course)

      file.serialize('./tmp/sup.xlsx')

      Models::PerformanceBookExport.create!(filename: 'sup')
    end

    private
    def create_summary_worksheet(workbook:)
      title_style = nil
      course_name = Axlsx::RichText.new

      workbook.styles do |style|
        title_style = style.add_style :alignment => { :horizontal=> :center }
        course_name.add_run(outputs.profile.name, b: true)
      end

      workbook.add_worksheet(name: 'Summary') do |sheet|
        sheet.add_row [title_style], style: title_style
      end
    end
  end
end
