require 'rails_helper'

RSpec.describe Api::V1::TaskingPlanRepresenter, type: :representer do

  let!(:tasking_plan) {
    instance_spy(Tasks::Models::TaskingPlan).tap do |dbl|
      ## bug work-around, see:
      ##   https://github.com/rspec/rspec-rails/issues/1309#issuecomment-118971828
      allow(dbl).to receive(:as_json).and_return(dbl)
    end
  }

  let(:representation) { ## NOTE: This is lazily-evaluated on purpose!
    Api::V1::TaskingPlanRepresenter.new(tasking_plan).as_json
  }

  context "target_id" do
    it "can be read" do
      allow(tasking_plan).to receive(:target_id).and_return(12)
      expect(representation).to include("target_id" => 12.to_s)
    end

    it "cannot be written (attempts are silently ignored)" do
      Api::V1::TaskingPlanRepresenter.new(tasking_plan).from_json({"target_id" => 42}.to_json)
      expect(tasking_plan).to have_received(:target_id=).with('42')
    end
  end

  context "target_type" do
    it "can be read ('CourseMembership::Models::Period' => 'period')" do
      allow(tasking_plan).to receive(:target_type).and_return('CourseMembership::Models::Period')
      expect(representation).to include("target_type" => 'period')
    end

    it "can be read ('Entity::Course' => 'course')" do
      allow(tasking_plan).to receive(:target_type).and_return('Entity::Course')
      expect(representation).to include("target_type" => 'course')
    end

    it "can be written ('period' => 'CourseMembership::Models::Period')" do
      rep = Api::V1::TaskingPlanRepresenter.new(tasking_plan).from_json({"target_type" => "period"}.to_json)
      expect(tasking_plan).to have_received(:target_type=).with('CourseMembership::Models::Period')
    end

    it "can be written ('course' => 'Entity::Course')" do
      Api::V1::TaskingPlanRepresenter.new(tasking_plan).from_json({"target_type" => "course"}.to_json)
      expect(tasking_plan).to have_received(:target_type=).with('Entity::Course')
    end
  end

  let!(:year_str)           { '2015' }
  let!(:daylight_month_str) { '06' }
  let!(:standard_month_str) { '01' }
  let!(:day_str)            { '04' }

  let!(:daylight_date_str) { "#{year_str}-#{daylight_month_str}-#{day_str}" }
  let!(:standard_date_str) { "#{year_str}-#{standard_month_str}-#{day_str}" }
  let!(:daylight_date_time_str) { "#{daylight_date_str}T14:32:34" }
  let!(:standard_date_time_str) { "#{standard_date_str}T14:32:34" }

  let!(:course_timezone)    { ActiveSupport::TimeZone['Central Time (US & Canada)'] }
  let!(:noncourse_timezone) { ActiveSupport::TimeZone['Pacific Time (US & Canada)'] }
  let!(:utc_timezone)       { ActiveSupport::TimeZone['UTC'] }

  context "opens_at" do

    let!(:daylight_opens_at) { course_timezone.parse(daylight_date_time_str) }
    let!(:standard_opens_at) { course_timezone.parse(standard_date_time_str) }

    it "can be read (date coerced to String)" do
      opens_at = Time.zone.now
      allow(tasking_plan).to receive(:opens_at).and_return(opens_at)
      expect(representation).to include("opens_at" => DateTimeUtilities::to_api_s(opens_at))
    end

    it "can be written with string containing date of form YYYY-MM-DDTHH:MM:SS" do
      Api::V1::TaskingPlanRepresenter.new(tasking_plan).from_json({"opens_at" => standard_date_time_str}.to_json)
      expect(tasking_plan).to have_received(:opens_at=).with(standard_opens_at)
    end

    it "time and timezone are ignored (upper edge)" do
      noncourse_timezone_opens_at = noncourse_timezone.parse("#{standard_date_str}T23:59:59")
      course_timezone_opens_at = course_timezone.parse("#{standard_date_str}T23:59:59")
      Api::V1::TaskingPlanRepresenter.new(tasking_plan)
                                     .from_json({"opens_at" => noncourse_timezone_opens_at.to_s}.to_json)
      expect(tasking_plan).to have_received(:opens_at=).with(course_timezone_opens_at)
    end

    it "time and timezone are ignored (lower edge)" do
      noncourse_timezone_opens_at = noncourse_timezone.parse("#{standard_date_str}T00:00:00")
      course_timezone_opens_at = course_timezone.parse("#{standard_date_str}T00:00:00")
      Api::V1::TaskingPlanRepresenter.new(tasking_plan)
                                     .from_json({"opens_at" => noncourse_timezone_opens_at.to_s}.to_json)
      expect(tasking_plan).to have_received(:opens_at=).with(course_timezone_opens_at)
    end

    it "DST is honored" do
      Api::V1::TaskingPlanRepresenter.new(tasking_plan)
                                     .from_json({"opens_at" => daylight_date_time_str.to_s}.to_json)
      expect(tasking_plan).to have_received(:opens_at=).with(daylight_opens_at)
    end
  end

  context "due_at" do

    let!(:daylight_due_at) { course_timezone.parse(daylight_date_time_str) }
    let!(:standard_due_at) { course_timezone.parse(standard_date_time_str) }

    it "can be read (date coerced to String)" do
      due_at = Time.zone.now
      allow(tasking_plan).to receive(:due_at).and_return(due_at)
      expect(representation).to include("due_at" => DateTimeUtilities::to_api_s(due_at))
    end

    it "can be written with string containing date of form YYYY-MM-DDTHH:MM:SS" do
      Api::V1::TaskingPlanRepresenter.new(tasking_plan).from_json({"due_at" => standard_date_time_str}.to_json)
      expect(tasking_plan).to have_received(:due_at=).with(standard_due_at)
    end

    it "time and timezone are ignored (upper edge)" do
      noncourse_timezone_due_at = noncourse_timezone.parse("#{standard_date_str}T23:59:59")
      course_timezone_due_at = course_timezone.parse("#{standard_date_str}T23:59:59")
      Api::V1::TaskingPlanRepresenter.new(tasking_plan)
                                     .from_json({"due_at" => noncourse_timezone_due_at.to_s}.to_json)
      expect(tasking_plan).to have_received(:due_at=).with(course_timezone_due_at)
    end

    it "time and timezone are ignored (lower edge)" do
      noncourse_timezone_due_at = noncourse_timezone.parse("#{standard_date_str}T00:00:00")
      course_timezone_due_at = course_timezone.parse("#{standard_date_str}T00:00:00")
      Api::V1::TaskingPlanRepresenter.new(tasking_plan)
                                     .from_json({"due_at" => noncourse_timezone_due_at.to_s}.to_json)
      expect(tasking_plan).to have_received(:due_at=).with(course_timezone_due_at)
    end

    it "DST is honored" do
      Api::V1::TaskingPlanRepresenter.new(tasking_plan)
                                     .from_json({"due_at" => daylight_date_time_str.to_s}.to_json)
      expect(tasking_plan).to have_received(:due_at=).with(daylight_due_at)
    end
  end
end
