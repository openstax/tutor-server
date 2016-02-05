require 'rails_helper'
require 'vcr_helper'

RSpec.describe Api::V1::ConceptCoach::PeriodStatsRepresenter, type: :representer do

  let(:period_stats) do
    {
      "period_id"                     => "42",
      "name"                          => "Test period",
      "mean_grade_percent"            => {
        "based_on_attempted_problems" => 50,
        "based_on_assigned_problems"  => 6
      },
      "total_count"                   => 6,
      "complete_count"                => 0,
      "partially_complete_count"      => 2,
      "current_pages"                 => [],
      "spaced_pages"                  => [],
      "trouble"                       => false
    }
  end

  subject(:representation) { described_class.new(Hashie::Mash.new(period_stats)).to_hash }

  context "period_id" do
    it "can be read" do
      expect(representation).to include("period_id" => "42")
    end

    it "cannot be written (attempts are silently ignored)" do
      expect(period_stats).to_not receive(:[]=)
      described_class.new(period_stats).from_json({"period_id" => "42"}.to_json)
    end
  end

  context "name" do
    it "can be read" do
      expect(representation).to include("name" => "Test period")
    end

    it "cannot be written (attempts are silently ignored)" do
      expect(period_stats).to_not receive(:[]=)
      described_class.new(period_stats).from_json({"name" => "Something else"}.to_json)
    end
  end

  context "mean_grade_percent" do
    it "can be read" do
      expect(representation).to include("mean_grade_percent" => {
        "based_on_attempted_problems" => 50,
        "based_on_assigned_problems" => 6
      })
    end

    it "cannot be written (attempts are silently ignored)" do
      expect(period_stats).to_not receive(:[]=)
      described_class.new(period_stats).from_json({"mean_grade_percent" => {}}.to_json)
    end
  end

  context "total_count" do
    it "can be read" do
      expect(representation).to include("total_count" => 6)
    end

    it "cannot be written (attempts are silently ignored)" do
      expect(period_stats).to_not receive(:[]=)
      described_class.new(period_stats).from_json({"total_count" => 12}.to_json)
    end
  end

  context "complete_count" do
    it "can be read" do
      expect(representation).to include("complete_count" => 0)
    end

    it "cannot be written (attempts are silently ignored)" do
      expect(period_stats).to_not receive(:[]=)
      described_class.new(period_stats).from_json({"complete_count" => 1}.to_json)
    end
  end

  context "partially_complete_count" do
    it "can be read" do
      expect(representation).to include("partially_complete_count" => 2)
    end

    it "cannot be written (attempts are silently ignored)" do
      expect(period_stats).to_not receive(:[]=)
      described_class.new(period_stats).from_json({"partially_complete_count" => 4}.to_json)
    end
  end

  context "current_pages" do
    it "can be read" do
      expect(representation).to include("current_pages" => [])
    end

    it "cannot be written (attempts are silently ignored)" do
      expect(period_stats).to_not receive(:[]=)
      described_class.new(period_stats).from_json({"current_pages" => []}.to_json)
    end
  end

  context "spaced_pages" do
    it "can be read" do
      expect(representation).to include("spaced_pages" => [])
    end

    it "cannot be written (attempts are silently ignored)" do
      expect(period_stats).to_not receive(:[]=)
      described_class.new(period_stats).from_json({"spaced_pages" => []}.to_json)
    end
  end

  context "is_trouble" do
    it "can be read" do
      expect(representation).to include("is_trouble" => false)
    end

    it "cannot be written (attempts are silently ignored)" do
      expect(period_stats).to_not receive(:[]=)
      described_class.new(period_stats).from_json({"is_trouble" => true}.to_json)
    end
  end

end
