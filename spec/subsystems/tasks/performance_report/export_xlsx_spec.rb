# Explicit requires to make testing faster (not loading whole app)

require 'spec_helper'

require 'xlsx_utils'
require_relative '../../../../app/subsystems/tasks/performance_report/export_xlsx'
require 'active_support/all'
require 'chronic'
require 'axlsx'
require 'xlsx_helper'
require 'roo'
require 'timecop'
require 'byebug'

RSpec.describe Tasks::PerformanceReport::ExportXlsx, type: :routine do

  context 'report_1' do
    before(:context) do
      Dir.mktmpdir do |dir|
        filepath = Timecop.freeze(Chronic.parse("3/18/2016 1:30PM")) do
          described_class.call(course_name: 'Physics 101',
                               report: report_1,
                               filename: "#{dir}/testfile")
        end

        # Uncomment this to open the file for visual inspection
        # `open "#{filepath}"` and sleep(0.5)

        expect{ @wb = Roo::Excelx.new(filepath) }.to_not raise_error
      end
    end

    it 'has good sheet titles' do
      expect(@wb.sheets).to eq ["1st - %", "1st - #"]
    end

    it 'puts students in alphabetical order' do
      expect(cell(11,2,0)).to eq "Gail"
    end

    it 'does not include a task due in the future' do
      (7..12).to_a.map{|row| expect(cell(row,17,0)).to be_blank}
    end

    it 'puts dropped students at the bottom' do
      expect(cell(19,1,0)).to eq "DROPPED"
      expect(cell(20,1,0)).to eq "Droppy"
      expect(cell(20,7,0)).to eq 2/9.0
    end

    context 'zeter\'s scores' do
      it 'has good HW scores' do
        expect(cell(12,7,0)).to eq 7/9.0
        expect(cell(12,8,0)).to eq 1.0
      end

      it 'shows reading\'s late comment and pending late work' do
        expect(cell(12,12,0)).to eq 1/3.0
        expect(comment(12,12,0)).to match /on due date: 33%/
        expect(cell(12,13,0)).to eq 2/3.0
        expect(cell(12,14,0)).to eq 2/3.0
        expect(cell(12,15,0)).to eq 1.0
        expect(cell(12,16,0).strftime("%-m/%-d/%Y")).to eq "3/7/2016"
      end
    end

    context 'abby\'s scores' do
      it 'shows homework late content and no pending late' do
        expect(cell(11,7,0)).to eq 4/9.0
        expect(comment(11,7,0)).to match /on due date: 22%/
        expect(cell(11,8,0)).to eq 1.0
        (9..11).to_a.map{|col|expect(cell(11,col,0)).to be_blank}
      end

      it 'shows nothing for her reading scores' do
        (12..16).to_a.map{|col|expect(cell(11,col,0)).to be_blank}
      end
    end
  end

  context 'report_1 when all due' do
    before(:context) do
      Dir.mktmpdir do |dir|
        filepath = Timecop.freeze(Chronic.parse("8/1/2016 1:30PM")) do
          described_class.call(course_name: 'Physics 101',
                               report: report_1,
                               filename: "#{dir}/testfile",
                               options: {stringify_formulas: true}) # so we can inspect formulas
        end

        expect{ @wb = Roo::Excelx.new(filepath) }.to_not raise_error
        @sheet1 = @wb.sheet(@wb.sheets.first)
      end
    end

    it 'has averages with disjoint cells' do
      expect(cell(11,4,0)).to match /.*AVERAGE\(G11,Q11\).*/
    end
  end

  context 'when a period has no students' do
    before(:context) do
      Dir.mktmpdir do |dir|
        filepath = Timecop.freeze(Chronic.parse("3/18/2016 1:30PM")) do
          described_class.call(course_name: 'Physics 101',
                               report: report_with_empty_students,
                               filename: "#{dir}/testfile",
                               options: {stringify_formulas: false})
        end

        # Uncomment this to open the file for visual inspection
        # `open "#{filepath}"` and sleep(0.5)

        expect{ @wb = Roo::Excelx.new(filepath) }.to_not raise_error
      end
    end

    it 'inserts an empty row so it does not explode with a circular reference' do
      [0,1].each do |sheet_number|
        expect(cell(11,1,sheet_number)).to eq '---'
        expect(cell(11,2,sheet_number)).to eq 'EMPTY'
        expect(cell(11,3,sheet_number)).to eq '---'
      end
    end
  end

  context 'with students who have nil names' do
    before(:context) do
      report_data = report_1
      report_data[0][:students][2][:first_name] = nil
      report_data[0][:students][2][:last_name] = nil

      Dir.mktmpdir do |dir|
        filepath = Timecop.freeze(Chronic.parse("3/18/2016 1:30PM")) do
          described_class.call(course_name: 'Physics 101',
                               report: report_data,
                               filename: "#{dir}/testfile")
        end

        # Uncomment this to open the file for visual inspection
        # `open "#{filepath}"` and sleep(0.5)
        expect{ @wb = Roo::Excelx.new(filepath) }.to_not raise_error
      end
    end

    it 'sorts them at the top (and does not blow up)' do
      names = (11..12).map{|row| "#{cell(row,1,0)}:#{cell(row,2,0)}" }
      expect(names).to eq([":", "Zeter:Zymphony"])
    end
  end

  context "when no HWs or Reading cols" do
    before(:context) do
      Dir.mktmpdir do |dir|
        filepath = described_class.call(course_name: 'Physics 101',
                                        report: report_with_empty_data,
                                        filename: "#{dir}/testfile",
                                        options: {stringify_formulas: false})

        # Uncomment this to open the file for visual inspection
        # `open "#{filepath}"` and sleep(0.5)

        expect{ @wb = Roo::Excelx.new(filepath) }.to_not raise_error
      end
    end

    it 'does not put in invalid formulas, e.g. "AVERAGE()" and "SUM()"' do
      invalid_formula = /AVERAGE\(\)|SUM\(\)/

      (4..6).to_a.each{|col| expect(cell(11,col,0)).not_to match(invalid_formula)}
      (4..6).to_a.each{|col| expect(cell(11,col,1)).not_to match(invalid_formula)}
      (4..6).to_a.each{|col| expect(cell(14,col,1)).not_to match(invalid_formula)}
    end
  end

  def cell(row,col,sheet_number)
    @wb.cell(row,col,@wb.sheets[sheet_number])
  end

  def comment(row,col,sheet_number)
    @wb.comment(row,col,@wb.sheets[sheet_number])
  end

  def report_1
    [
      {
        period: {
          name: "1st"
        },
        overall_average_score: 0.8,
        data_headings: [
          {
            title: "HW 4.2 Atoms and Isotopes - 4.3 Prokaryotic Cells",
            type: 'homework',
            due_at: Chronic.parse("3/15/2016")
          },
          {
            title: "External",
            type: 'external',
            due_at: Chronic.parse("3/14/2016")
          },
          {
            title: "Reading 4.1 Studying Cells",
            type: 'reading',
            due_at: Chronic.parse("3/5/2016")
          },
          {
            title: "Due-in-30-mins Homework",
            type: 'homework',
            due_at: Chronic.parse("3/18/2016 2PM")
          }
        ],
        students: [
          {
            name: "Zeter Zymphony",
            first_name: "Zeter",
            last_name: "Zymphony",
            student_identifier: "SID1",
            data: [
              {
                last_worked_at: Chronic.parse("3/13/2016 1PM"),
                step_count:                             9,
                completed_step_count:                   9,
                completed_on_time_step_count:           9,
                completed_accepted_late_step_count:     0,
                actual_and_placeholder_exercise_count:  9,
                completed_exercise_count:               9,
                completed_on_time_exercise_count:       9,
                completed_accepted_late_exercise_count: 0,
                correct_exercise_count:                 7,
                correct_on_time_exercise_count:         7,
                correct_accepted_late_exercise_count:   0,
              },
              {
                last_worked_at: Chronic.parse("3/13/2016 11AM"), # really more here but don't need
              },
              {
                last_worked_at: Chronic.parse("3/7/2016 1PM"),
                step_count:                             7,
                completed_step_count:                   6,
                completed_on_time_step_count:           5,
                completed_accepted_late_step_count:     1,
                actual_and_placeholder_exercise_count:  3,
                completed_exercise_count:               3,
                completed_on_time_exercise_count:       1,
                completed_accepted_late_exercise_count: 1,
                correct_exercise_count:                 2,
                correct_on_time_exercise_count:         1,
                correct_accepted_late_exercise_count:   0,
              },
              {
                last_worked_at: Chronic.parse("3/17/2016 1PM"),
                step_count:                             0,
                completed_step_count:                   0,
                completed_on_time_step_count:           0,
                completed_accepted_late_step_count:     0,
                actual_and_placeholder_exercise_count:  0,
                completed_exercise_count:               0,
                completed_on_time_exercise_count:       0,
                completed_accepted_late_exercise_count: 0,
                correct_exercise_count:                 0,
                correct_on_time_exercise_count:         0,
                correct_accepted_late_exercise_count:   0,
              }
            ],
            # average_score: 2/3.0
          },
          {
            name: "Droppy McDropFace",
            first_name: "Droppy",
            last_name: "McDropFace",
            student_identifier: "SID89",
            is_dropped: true,
            data: [
              {
                last_worked_at: Chronic.parse("3/13/2016 1PM"),
                step_count:                             9,
                completed_step_count:                   4,
                completed_on_time_step_count:           3,
                completed_accepted_late_step_count:     1,
                actual_and_placeholder_exercise_count:  9,
                completed_exercise_count:               4,
                completed_on_time_exercise_count:       3,
                completed_accepted_late_exercise_count: 1,
                correct_exercise_count:                 2,
                correct_on_time_exercise_count:         2,
                correct_accepted_late_exercise_count:   0,
              },
              nil,
              nil,
              nil
            ],
          },
          {
            name: "Abby Gail",
            first_name: "Abby",
            last_name: "Gail",
            student_identifier: "SID2",
            data: [
              {
                last_worked_at: Chronic.parse("3/15/2016 1PM"),
                step_count:                             9,
                completed_step_count:                   9,
                completed_on_time_step_count:           5,
                completed_accepted_late_step_count:     4,
                actual_and_placeholder_exercise_count:  9,
                completed_exercise_count:               9,
                completed_on_time_exercise_count:       5,
                completed_accepted_late_exercise_count: 4,
                correct_exercise_count:                 5,
                correct_on_time_exercise_count:         2,
                correct_accepted_late_exercise_count:   2,
              },
              {
                last_worked_at: Chronic.parse("3/13/2016 11AM"), # really more here but don't need
              },
              nil,
              {
                last_worked_at: Chronic.parse("3/15/2016 1PM"),
                step_count:                             0,
                completed_step_count:                   0,
                completed_on_time_step_count:           0,
                completed_accepted_late_step_count:     0,
                actual_and_placeholder_exercise_count:  0,
                completed_exercise_count:               0,
                completed_on_time_exercise_count:       0,
                completed_accepted_late_exercise_count: 0,
                correct_exercise_count:                 0,
                correct_on_time_exercise_count:         0,
                correct_accepted_late_exercise_count:   0,
              }
            ],
            # average_score: 2/3.0
          }
        ]
      }
    ]
  end

  def report_with_empty_students
    [
      {
        period: {
          name: "1st"
        },
        overall_average_score: 0.8,
        data_headings: [
          {
            title: "HW 4.2 Atoms and Isotopes - 4.3 Prokaryotic Cells",
            type: 'homework',
            due_at: Chronic.parse("3/15/2016")
          },
          {
            title: "External",
            type: 'external',
            due_at: Chronic.parse("3/14/2016")
          },
          {
            title: "Reading 4.1 Studying Cells",
            type: 'reading',
            due_at: Chronic.parse("3/5/2016")
          },
          {
            title: "Due-in-30-mins Homework",
            type: 'homework',
            due_at: Chronic.parse("3/18/2016 2PM")
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
          name: "1st"
        },
        overall_average_score: 0.8,
        data_headings: [],
        students: [
          {
            name: "Zeter Zymphony",
            first_name: "Zeter",
            last_name: "Zymphony",
            student_identifier: "SID1",
            data: [],
          },
          {
            name: "Abby Gail",
            first_name: "Abby",
            last_name: "Gail",
            student_identifier: "SID2",
            data: [],
          }
        ]
      }
    ]
  end


end
