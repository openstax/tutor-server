require 'rails_helper'

RSpec.describe TermYear, type: :lib do

  TESTED_YEARS = 2015..2017

  subject(:term_year) { described_class.new(term, year) }

  context 'legacy' do
    let(:term) { 'legacy'  }

    TESTED_YEARS.each do |year|
      context year.to_s do
        let(:year) { year }

        it 'always returns July 1st, 2015 00:00:00 AM as the start date' do
          start_date = DateTime.parse('July 1st, 2015 00:00:00 AM')
          expect(term_year.starts_at).to eq start_date
        end

        it 'always returns June 30th, 2017 11:59:59 PM as the end date' do
          end_date = DateTime.parse('June 30th, 2017 11:59:59 PM')
          expect(term_year.ends_at).to eq end_date
        end
      end
    end
  end

  context 'demo' do
    let(:term) { 'demo' }

    TESTED_YEARS.each do |year|
      context year.to_s do
        let(:year) { year }

        it "returns January 1st, #{year} 00:00:00 AM as the start date" do
          start_date = DateTime.parse("January 1st, #{year} 00:00:00 AM")
          expect(term_year.starts_at).to eq start_date
        end

        it "returns December 31st, #{year} 11:59:59 PM as the end date" do
          end_date = DateTime.parse("December 31st, #{year} 11:59:59 PM")
          expect(term_year.ends_at).to eq end_date
        end
      end
    end
  end

  context 'spring' do
    let(:term) { 'spring' }

    TESTED_YEARS.each do |year|
      context year.to_s do
        let(:year) { year }

        it "returns January 1st, #{year} 00:00:00 AM as the start date" do
          start_date = DateTime.parse("January 1st, #{year} 00:00:00 AM")
          expect(term_year.starts_at).to eq start_date
        end

        it "returns June 30th, #{year} 11:59:59 PM as the end date" do
          end_date = DateTime.parse("June 30th, #{year} 11:59:59 PM")
          expect(term_year.ends_at).to eq end_date
        end
      end
    end
  end

  context 'summer' do
    let(:term) { 'summer' }

    TESTED_YEARS.each do |year|
      context year.to_s do
        let(:year) { year }

        it "returns May 1st, #{year} 00:00:00 AM as the start date" do
          start_date = DateTime.parse("May 1st, #{year} 00:00:00 AM")
          expect(term_year.starts_at).to eq start_date
        end

        it "returns August 31st, #{year} 11:59:59 PM as the end date" do
          end_date = DateTime.parse("August 31st, #{year} 11:59:59 PM")
          expect(term_year.ends_at).to eq end_date
        end
      end
    end
  end

  context 'fall' do
    let(:term) { 'fall' }

    TESTED_YEARS.each do |year|
      context year.to_s do
        let(:year) { year }

        it "returns July 1st, #{year} 00:00:00 AM as the start date" do
          start_date = DateTime.parse("July 1st, #{year} 00:00:00 AM")
          expect(term_year.starts_at).to eq start_date
        end

        it "returns December 31st, #{year} 11:59:59 PM as the end date" do
          end_date = DateTime.parse("December 31st, #{year} 11:59:59 PM")
          expect(term_year.ends_at).to eq end_date
        end
      end
    end
  end
end
