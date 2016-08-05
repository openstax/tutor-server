require 'rails_helper'

RSpec.describe Salesforce::Remote::TermYear do

  context "#from_string" do
    it "works for Fall" do
      term_year = described_class.from_string("2015 - 16 Fall")

      expect(term_year.start_year).to eq 2015
      expect(term_year.end_year).to eq 2016
      expect(term_year).to be_fall
      expect(term_year).not_to be_spring
    end

    it "works for Spring" do
      term_year = described_class.from_string("2015 - 16 Spring")

      expect(term_year.start_year).to eq 2015
      expect(term_year.end_year).to eq 2016
      expect(term_year).not_to be_fall
      expect(term_year).to be_spring
    end

    it "works for nil" do
      term_year = described_class.from_string(nil)

      expect(term_year).to be_nil
    end

    it "freaks out for bad years" do
      expect{
        described_class.from_string("2015 - 17 Fall")
      }.to raise_error(StandardError)
    end

    it "freaks out for bad formats" do
      expect{
        described_class.from_string("fix formula 2016")
      }.to raise_error(described_class::ParseError)
    end
  end

  context "#initialize" do
    it "freaks out for bad terms" do
      expect{
        described_class.new(start_year: 2015, term: :blah)
      }.to raise_error(StandardError)
    end
  end

  context "#next" do
    it "moves from fall to spring" do
      expect(described_class.from_string("2015 - 16 Fall").next.to_s).to eq "2015 - 16 Spring"
    end

    it "moves from spring to fall" do
      expect(described_class.from_string("2015 - 16 Spring").next.to_s).to eq "2016 - 17 Fall"
    end
  end

  context "#guess_from_created_at" do
    it "guess early part of year into spring" do
      expect(
        described_class.guess_from_created_at(Time.zone.local(2016,2)).to_s
      ).to eq "2015 - 16 Spring"
    end

    it "guesses summerish into fall" do
      expect(
        described_class.guess_from_created_at(Time.zone.local(2016,5)).to_s
      ).to eq "2016 - 17 Fall"
    end

    it "guesses late fall into next spring" do
      expect(
        described_class.guess_from_created_at(Time.zone.local(2016,12)).to_s
      ).to eq "2016 - 17 Spring"
    end
  end

end
