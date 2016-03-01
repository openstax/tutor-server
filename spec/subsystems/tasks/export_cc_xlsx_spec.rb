require 'rails_helper'

RSpec.describe Tasks::PerformanceReport::ExportCcXlsx do

  it 'works' do
    puts 'running'
    described_class.call(course_name: "Physics 101", report: report_1, filename: 'testfile')
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
            title: "1.2 Basket weaving is really really hard",
            type: 'concept_coach',
            total_average: 0.56789,
            attempted_average: 0.8
          }
        ],
        students: [
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
                actual_and_placeholder_exercise_count: 7,
                completed_exercise_count: 5,
                correct_exercise_count: 2,
                recovered_exercise_count: 0
              }
            ]
          },
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
                actual_and_placeholder_exercise_count: 7,
                completed_exercise_count: 6,
                correct_exercise_count: 6,
                recovered_exercise_count: 0
              }
            ]
          }
        ]
      }
    ]
  end

end




