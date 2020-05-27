require 'rails_helper'

RSpec.describe Tasks::Models::TaskingPlan, type: :model do
  subject(:tasking_plan) { FactoryBot.create :tasks_tasking_plan }

  let(:task_plan)        { tasking_plan.task_plan }
  let(:target)           { tasking_plan.target }
  let(:course)           { task_plan.owner }

  it { is_expected.to belong_to(:target) }
  it { is_expected.to belong_to(:task_plan) }

  it { is_expected.to validate_presence_of(:opens_at_ntz) }
  it { is_expected.to validate_presence_of(:due_at_ntz) }
  it { is_expected.to validate_presence_of(:closes_at_ntz) }

  it "requires due_at to be in the future when changed after the task_plan is published" do
    publish_time = Time.current
    task_plan.first_published_at = publish_time
    task_plan.last_published_at = publish_time
    expect(tasking_plan).to be_valid
    tasking_plan.due_at = tasking_plan.time_zone.to_tz.now
    expect(tasking_plan).not_to be_valid
  end

  it "requires due_at to be after opens_at" do
    expect(tasking_plan).to be_valid
    tasking_plan.opens_at = tasking_plan.due_at
    expect(tasking_plan).to be_valid
    tasking_plan.opens_at = tasking_plan.due_at + 1.minute
    expect(tasking_plan).not_to be_valid
  end

  it "requires closes_at to be after due_at" do
    expect(tasking_plan).to be_valid
    tasking_plan.closes_at = tasking_plan.due_at - 1.hour
    expect(tasking_plan).not_to be_valid
  end

  it "requires opens_at to be after the course's starts_at, if the owner is a course" do
    expect(tasking_plan).to be_valid
    tasking_plan.opens_at = course.starts_at - 1.day
    expect(tasking_plan).not_to be_valid
    tasking_plan.opens_at = course.starts_at + 1.day
    expect(tasking_plan).to be_valid
  end

  it "requires closes_at to be before the course's ends_at, if the owner is a course" do
    expect(tasking_plan).to be_valid

    tasking_plan.closes_at = course.ends_at + 1.day
    expect(tasking_plan).not_to be_valid

    tasking_plan.closes_at = course.ends_at - 1.day
    expect(tasking_plan).to be_valid
  end

  it "requires target to be unique for the task_plan" do
    expect(tasking_plan).to be_valid

    expect(FactoryBot.build(:tasks_tasking_plan,
                             task_plan: task_plan,
                             target: target)).to_not be_valid
  end

  it "does not allow owner to assign to a period in another course" do
    period_1 = FactoryBot.create(:course_membership_period, course: course)
    period_2 = FactoryBot.create(:course_membership_period)

    expect(tasking_plan).to be_valid
    tasking_plan.target = period_1
    expect(tasking_plan).to be_valid
    tasking_plan.target = period_2
    expect(tasking_plan).not_to be_valid
  end

  it "validates even if the period has been deleted" do
    period = FactoryBot.create(:course_membership_period, course: course)

    expect(tasking_plan).to be_valid
    tasking_plan.target = period
    expect(tasking_plan).to be_valid
    period.destroy
    expect(tasking_plan).to be_valid
  end
end
