require 'rails_helper'

RSpec.describe HasTimezone, type: :lib do
  let(:tasking_plan) { FactoryBot.build :tasks_tasking_plan }
  let(:task)         { FactoryBot.build :tasks_task }

  it 'adds accessor methods for the listed fields' do
    expect(tasking_plan).to respond_to(:opens_at)
    expect(tasking_plan).to respond_to(:due_at)
    expect(tasking_plan).to respond_to(:opens_at=)
    expect(tasking_plan).to respond_to(:due_at=)

    expect(task).to respond_to(:opens_at)
    expect(task).to respond_to(:due_at)
    expect(task).to respond_to(:feedback_at)
    expect(task).to respond_to(:opens_at=)
    expect(task).to respond_to(:due_at=)
    expect(task).to respond_to(:feedback_at=)
  end

  it 'replaces input timezones with the record\'s timezone, ignoring offsets' do
    expect(task.feedback_at).to be_nil

    task_tz = task.time_zone
    task_time = task_tz.now

    task.feedback_at = task_time
    expect(task.feedback_at).to eq task_time

    test_tzs = [ActiveSupport::TimeZone['UTC']] + ActiveSupport::TimeZone.us_zones
    test_tzs.each do |tz|
      time = tz.now

      task.feedback_at = time
      expect(task.feedback_at.year).to eq time.year
      expect(task.feedback_at.month).to eq time.month
      expect(task.feedback_at.day).to eq time.day
      expect(task.feedback_at.hour).to eq time.hour
      expect(task.feedback_at.min).to eq time.min
      expect(task.feedback_at.sec).to eq time.sec
      expect(['CST', 'CDT']).to include task.feedback_at.zone
    end

    test_strings = ["2014-01-01 00:00:00", "2015-06-01 12:00:00", "2016-12-31 23:59:59",
                    "2017-01-01T00:00:00", "2018-06-01T12:00:00", "2019-12-31T23:59:59"]
    test_strings.each do |test_string|
      task.feedback_at = test_string
      expect(task.feedback_at).to eq task_tz.parse(test_string)
      expect(['CST', 'CDT']).to include task.feedback_at.zone
    end
  end
end

context 'timezone updates' do
  let(:task) { FactoryBot.build :tasks_task }

  it 'updates all associated times automagically' do
    task_time = task.time_zone.now
    task.feedback_at = task_time
    expect(task.feedback_at).to eq task_time

    test_tz_names = [ 'UTC' ] + CourseProfile::Models::Course::VALID_TIMEZONES
    test_tz_names.each do |tz_name|
      expect { task.course.timezone = tz_name }.to change { task.feedback_at.zone }

      # The zone changes but the numbers remain the same
      expect(task.feedback_at.year).to eq task_time.year
      expect(task.feedback_at.month).to eq task_time.month
      expect(task.feedback_at.day).to eq task_time.day
      expect(task.feedback_at.hour).to eq task_time.hour
      expect(task.feedback_at.min).to eq task_time.min
      expect(task.feedback_at.sec).to eq task_time.sec
    end
  end
end
