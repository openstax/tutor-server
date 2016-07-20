require 'rails_helper'

RSpec.describe BelongsToTimeZone, type: :lib do
  let(:time_zone) { FactoryGirl.create :time_zone }

  context 'default' do
    let(:course_profile) { FactoryGirl.build :course_profile_profile }

    it 'creates a time zone on save' do
      expect(course_profile.time_zone).to be_nil
      expect(course_profile.valid?).to eq true
      course_profile.save!
      expect(course_profile.time_zone).to be_a(::TimeZone)
      expect(course_profile.time_zone.name).to eq 'Central Time (US & Canada)'
    end
  end

  context 'fields' do
    let(:tasking_plan) { FactoryGirl.build :tasks_tasking_plan, time_zone: time_zone }
    let(:task)         { FactoryGirl.build :tasks_task,         time_zone: time_zone }

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

    it 'replaces input time_zones with the record\'s time_zone, ignoring offsets' do
      expect(task.feedback_at).to be_nil

      task_tz = time_zone.to_tz
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

  context 'time_zone updates' do
    let(:task) { FactoryGirl.build :tasks_task,         time_zone: time_zone }

    it 'updates all associated times automagically' do
      task_tz = time_zone.to_tz
      task_time = task_tz.now
      task.feedback_at = task_time
      expect(task.feedback_at).to eq task_time

      test_tz_names = [
        'UTC', 'Pacific Time (US & Canada)', 'Mountain Time (US & Canada)',
        'Central Time (US & Canada)', 'Eastern Time (US & Canada)'
      ]
      test_tz_names.each do |tz_name|
        expect{ task.time_zone.name = tz_name }.to change{ task.feedback_at.zone }

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

  it 'preserves previous_changes when no time zone set' do
    tz = ::TimeZone.create(name: 'Central Time (US & Canada)')
    course = Entity::Course.create
    profile = CourseProfile::Models::Profile.create(name: 'Blah', entity_course_id: course.id, is_concept_coach: false)
    expect(profile).to be_persisted
    expect(profile.previous_changes).not_to be_empty
  end

end
