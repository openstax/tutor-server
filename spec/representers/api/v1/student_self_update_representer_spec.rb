require 'rails_helper'

RSpec.describe Api::V1::StudentSelfUpdateRepresenter, type: :representer do
  let(:student) {
    instance_spy(CourseMembership::Models::Student).tap do |dbl|
      ## bug work-around, see:
      ##   https://github.com/rspec/rspec-rails/issues/1309#issuecomment-118971828
      allow(dbl).to receive(:as_json).and_return(dbl)
    end
  }

  let(:representation) { ## NOTE: This is lazily-evaluated on purpose!
    described_class.new(student).as_json
  }

  context "student_identifier" do
    it "can be read" do
      allow(student).to receive(:student_identifier).and_return("Student ID")
      expect(representation).to include("student_identifier" => "Student ID")
    end

    it "can be written" do
      described_class.new(student).from_json({"student_identifier" => "New Student ID"}.to_json)
      expect(student).to have_received(:student_identifier=).with("New Student ID")
    end
  end
end
