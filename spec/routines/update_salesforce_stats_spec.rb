require 'rails_helper'

RSpec.describe UpdateSalesforceStats, type: :routine do

  it 'updates a record on the happy stubbed path' do
    attached_record = OpenStruct.new(
      record: OpenStruct.new(changed?: true, save_if_changed: nil),
      attached_to: nil
    )
    allow(Salesforce::AttachedRecord).to receive(:all).and_return([attached_record])

    result = UpdateSalesforceStats.call

    expect(result.num_records).to eq 1
    expect(result.num_errors).to eq 0
    expect(result.num_updates).to eq 1
  end

  it 'does not update unchanged records' do
    attached_record = OpenStruct.new(
      record: OpenStruct.new(changed?: false, save_if_changed: nil),
      attached_to: nil
    )
    allow(Salesforce::AttachedRecord).to receive(:all).and_return([attached_record])

    result = UpdateSalesforceStats.call

    expect(result.num_records).to eq 1
    expect(result.num_errors).to eq 0
    expect(result.num_updates).to eq 0
  end

  it 'handles exceptions in the update section' do
    attached_record = OpenStruct.new(
      record: OpenStruct.new(changed?: false, save_if_changed: nil),
      attached_to: nil
    )
    allow(attached_record).to receive(:attached_to).and_raise "boom"
    allow(Salesforce::AttachedRecord).to receive(:all).and_return([attached_record])

    result = rescuing_exceptions do
      UpdateSalesforceStats.call
    end

    expect(result.num_records).to eq 1
    expect(result.num_errors).to eq 1
    expect(result.num_updates).to eq 0
    expect(attached_record.record.error).to eq "Unable to update stats: boom"
  end

  it 'handles exceptions in the save section' do
    attached_record = OpenStruct.new(
      record: OpenStruct.new(changed?: nil, save_if_changed: nil),
      attached_to: nil
    )
    allow(attached_record.record).to receive(:changed?).and_raise "boom"
    allow(Salesforce::AttachedRecord).to receive(:all).and_return([attached_record])

    result = rescuing_exceptions do
      UpdateSalesforceStats.call
    end

    expect(result.num_records).to eq 1
    expect(result.num_errors).to eq 1
    expect(result.num_updates).to eq 0
    expect(attached_record.record.error).to eq nil
  end

end
