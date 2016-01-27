require 'rails_helper'

RSpec.describe UpdateSalesforceStats, type: :routine do

  let!(:course)          { Entity::Course.create! }
  let!(:record)          { OpenStruct.new(changed?: false, save: nil) }
  let!(:attached_record) { OpenStruct.new(salesforce_class_name: 'Salesforce::Remote::ClassSize',
                                          tutor_gid: course.to_global_id, record: record) }

  before(:each) do
    allow(Salesforce::AttachedRecord).to receive(:preload).and_return([attached_record])
  end

  it 'updates a record on the happy stubbed path' do
    record[:changed?] = true
    outputs = UpdateSalesforceStats.call.outputs

    expect(outputs[:num_records]).to eq 1
    expect(outputs[:num_errors]).to eq 0
    expect(outputs[:num_updates]).to eq 1
  end

  it 'does not update unchanged records' do
    outputs = UpdateSalesforceStats.call.outputs

    expect(outputs[:num_records]).to eq 1
    expect(outputs[:num_errors]).to eq 0
    expect(outputs[:num_updates]).to eq 0
  end

  it 'handles exceptions in the update section' do
    allow_any_instance_of(Entity::Course).to receive(:teachers).and_raise "boom"

    outputs = rescuing_exceptions{ UpdateSalesforceStats.call.outputs }

    expect(outputs[:num_records]).to eq 1
    expect(outputs[:num_errors]).to eq 1
    expect(outputs[:num_updates]).to eq 0
    expect(attached_record.record.error).to eq "Unable to update stats: boom"
  end

  it 'handles exceptions in the save section' do
    allow(record).to receive(:changed?).and_raise "boom"

    outputs = rescuing_exceptions{ UpdateSalesforceStats.call.outputs }

    expect(outputs[:num_records]).to eq 1
    expect(outputs[:num_errors]).to eq 1
    expect(outputs[:num_updates]).to eq 0
    expect(attached_record.record.error).to eq nil
  end

end
