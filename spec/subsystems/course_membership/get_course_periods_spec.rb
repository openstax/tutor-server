require 'rails_helper'

describe CourseMembership::GetCoursePeriods do
  let(:target_course) { Entity::Course.create! }

  context "when there are no periods for the target course" do
    it "returns an empty enumerable" do
      result = CourseMembership::GetCoursePeriods.call(course: target_course)
      expect(result.errors).to be_empty
      expect(result.outputs.periods).to be_empty
    end
  end

  context "when there is one period for the target course" do
    let!(:target_period) { CreatePeriod[course: target_course] }

    it "returns an enumerable containing that period" do
      result = CourseMembership::GetCoursePeriods.call(course: target_course)
      expect(result.errors).to be_empty
      expect(result.outputs.periods.count).to eq(1)
      expect(result.outputs.periods).to include(target_period)
    end
  end

  context "when there are multiple periods for the target course" do
    let!(:target_periods) { 2.times.map { CreatePeriod[course: target_course] } }

    it "returns an enumerable containing those periods" do
      result = CourseMembership::GetCoursePeriods.call(course: target_course)
      expect(result.errors).to be_empty
      expect(result.outputs.periods.count).to eq(target_periods.count)
      target_periods.each do |target_period|
        expect(result.outputs.periods).to include(target_period)
      end
    end
  end
end
