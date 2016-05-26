require 'rails_helper'
require 'tmpdir'

RSpec.describe Tasks::PerformanceReport::ExportCcXlsx do

  it 'does not explode and passes spot checks' do
    Dir.mktmpdir do |dir|
      filepath = described_class.call(course_name: "Physics 101", report: report_1, filename: "#{dir}/testfile")

      wb = nil
      expect{ wb = Roo::Excelx.new(filepath) }.to_not raise_error

      expect(wb.sheets).to eq ["1st Period - %", "1st Period - #"]

      sheet1 = wb.sheet(wb.sheets.first)

      expect(sheet1.cell(11,2)).to eq "Gail"
      expect(0.81..0.82).to cover(sheet1.cell(13,4))
      expect(wb.comment?(13,4,"1st Period - %")).to be_truthy
      expect(wb.celltype(11,9,wb.sheets.first)).to eq :date

      [4, 5, 6].each{|col| expect(wb.empty?(11,col,wb.sheets.last)).to be_truthy}
    end
  end

  def report_1
    [
      {
        period: {
          name: "1st Period"
        } ,
        data_headings: [
          {
            cnx_page_id: 'UUID_1',
            title: "1.1 Intro to Math",
            type: 'concept_coach',
            total_average: 0.6,
            attempted_average: 0.7123
          },
          {
            cnx_page_id: "UUID_2",
            title: "1.2 Basket weaving is really really really really really (wrap test) hard",
            type: 'concept_coach',
            total_average: 0.56789,
            attempted_average: 0.8
          }
        ],
        students: [
          {
            name: "Abby Gail",
            first_name: "Abby",
            last_name: "Gail",
            student_identifier: "SID2",
            role: nil,
            data: [
              nil,
              {
                late: false,
                status: 'in_progress',
                type: 'concept_coach',
                id: 44,
                due_at: Chronic.parse("3/15/2016 1PM"),
                last_worked_at: Chronic.parse("3/2/2016 3PM"),
                actual_and_placeholder_exercise_count: 9,
                completed_exercise_count: 8,
                correct_exercise_count: 8,
                recovered_exercise_count: 0
              }
            ]
          },
          {
            name: "Jimmy John",
            first_name: "Jimmy",
            last_name: "John",
            student_identifier: "SID3",
            role: nil,
            data: [
              nil,
              {
                late: false,
                status: 'in_progress',
                type: 'concept_coach',
                id: 44,
                due_at: Chronic.parse("3/15/2016 1PM"),
                last_worked_at: Chronic.parse("3/2/2016 4PM"),
                actual_and_placeholder_exercise_count: 9,
                completed_exercise_count: 4,
                correct_exercise_count: 2,
                recovered_exercise_count: 0
              }
            ]
          },
          {
            name: "Zeter Zymphony",
            first_name: "Zeter",
            last_name: "Zymphony",
            student_identifier: "SID1",
            role: nil,
            data: [
              {
                late: false,
                status: 'completed',
                type: 'concept_coach',
                id: 43,
                due_at: Chronic.parse("2/29/2016 1PM"),
                last_worked_at: Chronic.parse("2/29/2016 11AM"),
                actual_and_placeholder_exercise_count: 11,
                completed_exercise_count: 11,
                correct_exercise_count: 9,
                recovered_exercise_count: 0
              },
              {
                late: true,
                status: 'in_progress',
                type: 'concept_coach',
                id: 44,
                due_at: Chronic.parse("3/15/2016 1PM"),
                last_worked_at: Chronic.parse("3/17/2016 5PM"),
                actual_and_placeholder_exercise_count: 9,
                completed_exercise_count: 5,
                correct_exercise_count: 2,
                recovered_exercise_count: 0
              }
            ]
          }
        ]
      }
    ]
  end

end
