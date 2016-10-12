require 'rails_helper'

RSpec.describe CourseMembership::GetCoursePeriods do
  let(:target_course) { FactoryGirl.create :entity_course }

  context "when there are no periods for the target course" do
    it "returns an empty enumerable" do
      result = CourseMembership::GetCoursePeriods.call(course: target_course)
      expect(result.errors).to be_empty
      expect(result.outputs.periods).to be_empty
    end
  end

  context "when there is one period for the target course" do
    let!(:target_period) do
      model = FactoryGirl.create :course_membership_period, course: target_course
      CourseMembership::Period.new(strategy: model.wrap)
    end

    it "returns an enumerable containing that period" do
      result = CourseMembership::GetCoursePeriods.call(course: target_course)
      expect(result.errors).to be_empty
      expect(result.outputs.periods.count).to eq(1)
      expect(result.outputs.periods).to include(target_period)
    end
  end

  context "when there are multiple periods for the target course" do
    let!(:target_periods) do
      2.times.map do
        model = FactoryGirl.create :course_membership_period, course: target_course
        CourseMembership::Period.new(strategy: model.wrap)
      end
    end

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
