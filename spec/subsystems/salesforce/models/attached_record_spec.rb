require 'rails_helper'

RSpec.describe Salesforce::Models::AttachedRecord, type: :model do

  context "factory instance" do
    it "has good defaults" do
      ar = FactoryBot.create :salesforce_attached_record
      expect(ar.tutor_gid).to match /CourseProfile::Models::Course/
      expect(ar.salesforce_class).to eq OpenStax::Salesforce::Remote::OsAncillary
      expect(ar.salesforce_id).to eq "foo"
    end

    it "can take tutor object" do
      period = FactoryBot.create :course_membership_period
      ar = FactoryBot.create :salesforce_attached_record, tutor_object: period
      expect(ar.tutor_gid).to match /CourseMembership::Models::Period\/#{period.id}/
    end

    it "can take sf object" do
      cs = OpenStax::Salesforce::Remote::ClassSize.new(id: "blah")
      ar = FactoryBot.create :salesforce_attached_record, salesforce_object: cs
      expect(ar.salesforce_class).to eq OpenStax::Salesforce::Remote::ClassSize
      expect(ar.salesforce_id).to eq "blah"
    end
  end

  context "attached_to stuff" do
    let(:ar) { FactoryBot.create :salesforce_attached_record,
                                   tutor_object: CourseProfile::Models::Course.new(id: 432) }

    it "returns attached_to_id" do
      expect(ar.attached_to_id).to eq 432
    end

    it "returns attached_to_class_name" do
      expect(ar.attached_to_class_name).to eq "CourseProfile::Models::Course"
    end
  end

end
