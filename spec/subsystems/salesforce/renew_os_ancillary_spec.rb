require 'rails_helper'

RSpec.describe Salesforce::RenewOsAncillary do

  it "freaks out if too many target opportunities" do
    based_on = OpenStruct.new(opportunity: OpenStruct.new)
    allow(Salesforce::Remote::Opportunity).to receive(:where) { [1,2,3] }

    expect{
      described_class.call(based_on: based_on, renew_for_term_year: 'dummy')
    }.to raise_error Salesforce::OsAncillaryRenewalError
  end

  it "freaks out if no target opportunities" do
    based_on = OpenStruct.new(opportunity: OpenStruct.new)
    allow(Salesforce::Remote::Opportunity).to receive(:where) { [] }

    expect{
      described_class.call(based_on: based_on, renew_for_term_year: 'dummy')
    }.to raise_error Salesforce::OsAncillaryRenewalError
  end

  it "queries the right opportunities" do
    based_on = OpenStruct.new(opportunity: OpenStruct.new(contact_id: '123',
                                                          book_name: "A & P"))
    term_year = Salesforce::Remote::TermYear.from_string("2015 - 16 Fall")

    # Cause early termination
    allow(Salesforce::Remote::Opportunity).to receive(:where) { [] }

    expect(Salesforce::Remote::Opportunity).to receive(:where).with({
      contact_id: "123",
      book_name: "A & P",
      term_year: "2015 - 16 Fall"
    })

    described_class.call(based_on: based_on, renew_for_term_year: term_year) rescue StandardError
  end

  it "reuses an existing OSA if available" do
    based_on = OpenStruct.new(opportunity: OpenStruct.new)
    target_opportunity = OpenStruct.new
    allow(Salesforce::Remote::Opportunity).to receive(:where) { [target_opportunity] }
    allow(Salesforce::Remote::OsAncillary).to receive(:where) { ["dummy"] }

    expect(Salesforce::Remote::OsAncillary).not_to receive(:new)

    returned = described_class.call(based_on: based_on, renew_for_term_year: "fake")

    expect(returned).to eq "dummy"
  end

  it "can run successfully" do
    based_on = OpenStruct.new(opportunity: OpenStruct.new, product: "Tutor", course_id: "42", teacher_join_url: 'a_url')
    target_opportunity = OpenStruct.new(id: 'target_opp_id')
    allow(Salesforce::Remote::Opportunity).to receive(:where) { [target_opportunity] }
    allow(Salesforce::Remote::OsAncillary).to receive(:where) { [] }

    allow_any_instance_of(Salesforce::Remote::OsAncillary).to receive(:save) { true }

    returned = described_class.call(based_on: based_on, renew_for_term_year: "fake")

    expect(returned).to be_a Salesforce::Remote::OsAncillary

    expect(returned.opportunity_id).to eq 'target_opp_id'
    expect(returned.product).to eq "Tutor"
    expect(returned.course_id).to eq "42"
    expect(returned.status).to eq "Approved"
    expect(returned.teacher_join_url).to eq "a_url"
    expect(returned.error).to be_nil
  end

  it "freaks out if save fails" do
    based_on = OpenStruct.new(opportunity: OpenStruct.new, product: "Tutor", course_id: "42")
    target_opportunity = OpenStruct.new(id: 'target_opp_id')
    allow(Salesforce::Remote::Opportunity).to receive(:where) { [target_opportunity] }
    allow(Salesforce::Remote::OsAncillary).to receive(:where) { [] }

    allow_any_instance_of(Salesforce::Remote::OsAncillary).to receive(:save) { false }

    expect {
      described_class.call(based_on: based_on, renew_for_term_year: "fake")
    }.to raise_error Salesforce::OsAncillaryRenewalError
  end

  it "can find the methods it needs in potential SF object classes" do
    # Have this check since we're mostly otherwise stubbing these classes
    [Salesforce::Remote::OsAncillary, Salesforce::Remote::ClassSize].each do |sf_class|
      expect(sf_class.new).to respond_to(:opportunity, :product, :save)
    end
  end

end
