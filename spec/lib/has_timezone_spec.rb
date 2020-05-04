require 'rails_helper'

RSpec.describe HasTimezone, type: :lib do
  let(:tasking_plan) { FactoryBot.build :tasks_tasking_plan }
  let(:task)         { FactoryBot.build :tasks_task }

  it 'adds accessor methods for the listed fields' do
    expect(tasking_plan).to respond_to(:opens_at)
    expect(tasking_plan).to respond_to(:due_at)
    expect(tasking_plan).to respond_to(:closes_at)
    expect(tasking_plan).to respond_to(:opens_at=)
    expect(tasking_plan).to respond_to(:due_at=)
    expect(tasking_plan).to respond_to(:closes_at=)

    expect(task).to respond_to(:opens_at)
    expect(task).to respond_to(:due_at)
    expect(task).to respond_to(:closes_at)
    expect(task).to respond_to(:opens_at=)
    expect(task).to respond_to(:due_at=)
    expect(task).to respond_to(:closes_at=)
  end

  it 'replaces input timezones with the record\'s timezone, ignoring offsets' do
    task_tz = task.time_zone
    task_time = task_tz.now

    expect(task.closes_at).not_to eq task_time

    task.closes_at = task_time
    expect(task.closes_at).to eq task_time

    test_tzs = [ActiveSupport::TimeZone['UTC']] + ActiveSupport::TimeZone.us_zones
    test_tzs.each do |tz|
      time = tz.now

      task.closes_at = time
      expect(task.closes_at.year).to eq time.year
      expect(task.closes_at.month).to eq time.month
      expect(task.closes_at.day).to eq time.day
      expect(task.closes_at.hour).to eq time.hour
      expect(task.closes_at.min).to eq time.min
      expect(task.closes_at.sec).to eq time.sec
      expect(['CST', 'CDT']).to include task.closes_at.zone
    end

    test_strings = ["2014-01-01 00:00:00", "2015-06-01 12:00:00", "2016-12-31 23:59:59",
                    "2017-01-01T00:00:00", "2018-06-01T12:00:00", "2019-12-31T23:59:59"]
    test_strings.each do |test_string|
      task.closes_at = test_string
      expect(task.closes_at).to eq task_tz.parse(test_string)
      expect(['CST', 'CDT']).to include task.closes_at.zone
    end
  end
end

context 'timezone updates' do
  let(:task) { FactoryBot.build :tasks_task }

  it 'updates all associated times automagically' do
    task_time = task.time_zone.now
    task.closes_at = task_time
    expect(task.closes_at).to eq task_time
    task.save validate: false

    test_tz_names = [ 'UTC' ] + CourseProfile::Models::Course::VALID_TIMEZONES
    test_tz_names.each do |tz_name|
      expect do
        task.course.update_attribute :timezone, tz_name
      end.to change { task.reload.closes_at.zone }

      # The zone changes but the numbers remain the same
      expect(task.reload.closes_at.year).to eq task_time.year
      expect(task.closes_at.month).to eq task_time.month
      expect(task.closes_at.day).to eq task_time.day
      expect(task.closes_at.hour).to eq task_time.hour
      expect(task.closes_at.min).to eq task_time.min
      expect(task.closes_at.sec).to eq task_time.sec
    end
  end
end
