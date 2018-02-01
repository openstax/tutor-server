require 'rails_helper'

RSpec.describe Tasks::PerformanceReport::ExportCcXlsx do

  before(:all) { @course = FactoryBot.create :course_profile_course }

  context 'report_1' do
    before(:all) do
      DatabaseCleaner.start

      Dir.mktmpdir do |dir|
        filename = Timecop.freeze(Chronic.parse("3/18/2016 1:30PM")) do
          # stringify formulas otherwise formulas are read as nil by roo
          described_class.call(course: @course,
                               report: report_1,
                               filename: "#{dir}/testfile",
                               options: {stringify_formulas: true}).outputs.filename
        end

        # Uncomment this to open the file for visual inspection
        # `open "#{filename}"` and sleep(0.5)

        expect{ @wb = Roo::Excelx.new(filename) }.to_not raise_error
      end
    end
    after(:all) { DatabaseCleaner.clean }

    it 'has good sheets' do
      expect(@wb.sheets).to eq ["1st Period - %", "1st Period - #"]
    end

    it 'has students in alphabetical order' do
      expect(cell(13,2,0)).to eq "Gail"
    end

    it 'has % class averages' do
      expect(cell(16,8,0)).to match /AVERAGE\(H13:H15\)/
      expect(cell(16,9,0)).to match /AVERAGE\(I13:I15\)/
    end

    it 'has % student averages' do
      expect(cell(15,4,0)).to match /AVERAGEIF\(E8:J8.*E15:J15\)/
    end

    it 'has a date in the right place' do
      expect(@wb.celltype(15,7,@wb.sheets.first)).to eq :date
    end

    it 'has count class averages' do
      expect(cell(16,4,1)).to eq "AVERAGE(D13:D15)"
      expect(cell(16,5,1)).to eq "AVERAGE(E13:E15)"
    end

    it 'does not have content beyond where it should' do
      (10..16).to_a.each{|ii| expect(cell(ii,11,0)).to be_blank}
      (10..16).to_a.each{|ii| expect(cell(ii,14,1)).to be_blank}
    end

    it 'puts in zeros where there is no work yet' do
      expect(cell(13,5,0)).to eq 0
      expect(cell(13,6,0)).to eq 0
      expect(cell(13,6,1)).to eq 0
      expect(cell(13,7,1)).to eq 0
    end

    it 'puts dropped students at the bottom' do
      expect(cell(23,1,0)).to eq "Droppy"
      expect(cell(23,2,0)).to eq "McDropface"
      expect(cell(23,10,0).strftime("%-m/%-d/%Y")).to eq "3/2/2016"
    end
  end

  context 'when a period has no students' do
    before(:all) do
      DatabaseCleaner.start

      Dir.mktmpdir do |dir|
        filename = Timecop.freeze(Chronic.parse("3/18/2016 1:30PM")) do
          described_class.call(course: @course,
                               report: report_with_empty_period,
                               filename: "#{dir}/testfile",
                               options: {stringify_formulas: false}).outputs.filename
        end

        # Uncomment this to open the file for visual inspection
        # `open "#{filename}"` and sleep(0.5)

        expect{ @wb = Roo::Excelx.new(filename) }.to_not raise_error
      end
    end
    after(:all) { DatabaseCleaner.clean }

    it 'inserts an empty row so it does not explode with a circular reference' do
      [0,1].each do |sheet_number|
        expect(cell(13,1,sheet_number)).to eq '---'
        expect(cell(13,2,sheet_number)).to eq 'EMPTY'
        expect(cell(13,3,sheet_number)).to eq '---'
      end
    end
  end

  context 'when a period has no data' do
    before(:all) do
      DatabaseCleaner.start

      Dir.mktmpdir do |dir|
        filename = described_class.call(course: @course,
                                        report: report_with_empty_data,
                                        filename: "#{dir}/testfile",
                                        options: {stringify_formulas: false}).outputs.filename

        # Uncomment this to open the file for visual inspection
        # `open "#{filename}"` and sleep(0.5)

        expect{ @wb = Roo::Excelx.new(filename) }.to_not raise_error
      end
    end
    after(:all) { DatabaseCleaner.clean }

    # it 'does not put in invalid formulas that explode when open in Excel (requires manual testing)' do
    #   # uncomment this example and the `open` call above to manually test that the file
    #   # opens in Excel (no way to test this automatically)
    # end
  end

  def cell(row,col,sheet_number)
    @wb.cell(row,col,@wb.sheets[sheet_number])
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
            attempted_average: 0.7123,
            average_actual_and_placeholder_exercise_count: 11
          },
          {
            cnx_page_id: "UUID_2",
            title: "1.2 Basket weaving is really really really really really (wrap test) hard",
            type: 'concept_coach',
            total_average: 0.56789,
            attempted_average: 0.8,
            average_actual_and_placeholder_exercise_count: 11
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
            name: "Droppy McDropface",
            first_name: "Droppy",
            last_name: "McDropface",
            student_identifier: "SID4000",
            is_dropped: true,
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
                completed_exercise_count: 7,
                correct_exercise_count: 6,
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

  def report_with_empty_period
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
            attempted_average: 0.7123,
            average_actual_and_placeholder_exercise_count: 11
          },
          {
            cnx_page_id: "UUID_2",
            title: "1.2 Basket weaving is really really really really really (wrap test) hard",
            type: 'concept_coach',
            total_average: 0.56789,
            attempted_average: 0.8,
            average_actual_and_placeholder_exercise_count: 11
          }
        ],
        students: []
      }
    ]
  end

  def report_with_empty_data
    [
      {
        period: {
          name: "1st Period"
        } ,
        data_headings: [],
        students: [
          {
            name: "Abby Gail",
            first_name: "Abby",
            last_name: "Gail",
            student_identifier: "SID2",
            role: nil,
            data: []
          },
          {
            name: "Jimmy John",
            first_name: "Jimmy",
            last_name: "John",
            student_identifier: "SID3",
            role: nil,
            data: []
          },
          {
            name: "Zeter Zymphony",
            first_name: "Zeter",
            last_name: "Zymphony",
            student_identifier: "SID1",
            role: nil,
            data: []
          }
        ]
      }
    ]
  end

end
