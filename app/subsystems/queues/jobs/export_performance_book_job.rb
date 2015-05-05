module Queues
  module Jobs
    class ExportPerformanceBookJob < ActiveJob::Base
      queue_as :default

      def perform(role:, course:)
        axlsx_package = Axlsx::Package.new
        workbook = axlsx_package.workbook

        create_summary_worksheet(workbook: workbook, course: course)

        axlsx_package.serialize('./tmp/sup.xlsx')

        Tasks::Models::PerformanceBookExport.create!(filename: 'sup')
      end

      private
      def create_summary_worksheet(workbook:, course:)
        center = nil
        rich_text = Axlsx::RichText.new
        profile = GetCourseProfile[course: course]

        workbook.styles do |style|
          center = style.add_style :alignment => { :horizontal=> :center }
          rich_text.add_run(profile.name, b: true)
        end

        workbook.add_worksheet(name: 'Summary') do |sheet|
          sheet.add_row [rich_text], style: center
        end
      end
    end
  end
end
