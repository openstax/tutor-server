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

  let!(:central_time) { ActiveSupport::TimeZone['Central Time (US & Canada)'] }
  let!(:pacific_time) { ActiveSupport::TimeZone['Pacific Time (US & Canada)'] }
  let!(:utc_timezone) { ActiveSupport::TimeZone['UTC'] }

  context "opens_at & due_at" do

    let!(:daylight_date_time) { central_time.parse(daylight_date_time_str) }
    let!(:standard_date_time) { central_time.parse(standard_date_time_str) }

    %w(opens_at due_at).each do |field|
      context field do
        it "can be read (date coerced to String)" do
          datetime = Time.zone.now
          allow(tasking_plan).to receive(field).and_return(datetime)
          expect(representation).to include(field => DateTimeUtilities::to_api_s(datetime))
        end

        it "can be written with string containing date of form YYYY-MM-DDTHH:MM:SS" do
          consume(input: {field => standard_date_time_str}, to: tasking_plan, time_zone: central_time)
          expect(tasking_plan).to have_received("#{field}=").with(standard_date_time)
        end

        it "timezone is ignored (upper edge)" do
          pacific_date_time = pacific_time.parse("#{standard_date_str}T23:59:59")
          central_date_time = central_time.parse("#{standard_date_str}T23:59:59")

          consume(input: {field => pacific_date_time.to_s}, time_zone: central_time)

          expect(tasking_plan).to have_received("#{field}=").with(central_date_time)
        end

        it "timezone is ignored (lower edge)" do
          pacific_date_time = pacific_time.parse("#{standard_date_str}T00:00:00")
          central_date_time = central_time.parse("#{standard_date_str}T00:00:00")

          consume(input: {field => pacific_date_time.to_s}, time_zone: central_time)

          expect(tasking_plan).to have_received("#{field}=").with(central_date_time)
        end

        it "DST is honored" do
          consume(input: {field => daylight_date_time_str.to_s}, time_zone: central_time)
          expect(tasking_plan).to have_received("#{field}=").with(daylight_date_time)
        end
      end
    end
  end

  # A helper for reading input (json or hash) into a TaskingPlan.  Reflects what happens
  # in the task plan controller (has the same `use_zone` wrapping)
  def consume(input:, to: tasking_plan, time_zone:)
    Time.use_zone(time_zone) do
      described_class.new(to).from_json(
        case input
        when String
          input
        when Hash
          input.to_json
        else
          raise StandardError
        end
      )
    end
  end

end
