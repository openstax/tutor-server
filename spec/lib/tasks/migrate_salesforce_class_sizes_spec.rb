require 'rails_helper'

describe "migrate_salesforce_class_sizes", type: :rake do
  include_context "rake"

  let(:class_size) { Salesforce::Remote::ClassSize.new(os_ancillary_id: "osa_id", id: "id") }

  it "ignores OSAs" do
    stub_attached_records(Salesforce::Remote::OsAncillary.new)
    expect(capture_stdout{call}).to be_blank
  end

  it "bails out if no osa reference" do
    class_size.os_ancillary_id = nil
    stub_attached_records(class_size)

    expect(
      capture_stdout{call}
    ).to eq "In AR 0, ClassSize id does not point to a new OsAncillary!\n"
  end

  it "defaults to a dry run and sets values" do
    stubs = stub_attached_records(class_size)

    expect(
      capture_stdout{call}
    ).to eq "In AR 0, ClassSize id has changed to OsAncillary osa_id (dry run)\n"

    expect(stubs.first.salesforce_class_name).to eq "Salesforce::Remote::OsAncillary"
    expect(stubs.first.salesforce_id).to eq "osa_id"
    expect(stubs.first.salesforce_object).to eq class_size # not changed for dry run
  end

  it "saves for real runs" do
    stubs = stub_attached_records(class_size)
    expect(stubs.first).to receive(:save!)

    expect(
      capture_stdout{call('real')}
    ).to eq "In AR 0, ClassSize id has changed to OsAncillary osa_id (saved!)\n"

    expect(stubs.first.salesforce_object).to be_nil
  end

  def stub_attached_records(salesforce_objects)
    salesforce_objects = [salesforce_objects].flatten

    stubs = salesforce_objects.map.with_index do |salesforce_object, ii|
      OpenStruct.new(id: ii,
                     salesforce_class_name: salesforce_object.class.name,
                     salesforce_id: salesforce_object.id,
                     salesforce_object: salesforce_object,
                     save!: nil)
    end

    allow(Salesforce::Models::AttachedRecord).to receive(:preload) { stubs }

    stubs
  end

end
