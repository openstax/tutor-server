require 'rails_helper'

RSpec.describe TermYear, type: :lib do

  CURRENT_YEAR = Time.current.year
  TESTED_YEARS = CURRENT_YEAR-1..CURRENT_YEAR+1

  subject(:term_year) { described_class.new(term, year) }

  context 'legacy' do
    let(:term) { 'legacy' }

    TESTED_YEARS.each do |year|
      context year.to_s do
        let(:year) { year }

        it 'ignores the given year and returns July 1st, 2015 00:00:00 AM as the start date' do
          start_date = DateTime.parse('July 1st, 2015 00:00:00 AM')
          expect(term_year.starts_at).to eq start_date
        end

        it 'ignores the given year and returns Dec 31st, 2016 11:59:59 PM as the end date' do
          end_date = DateTime.parse('Dec 31st, 2016 11:59:59 PM')
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

        it "returns July 1st, #{year - 1} 00:00:00 AM as the start date" do
          start_date = DateTime.parse("July 1st, #{year - 1} 00:00:00 AM")
          expect(term_year.starts_at).to eq start_date
        end

        it "returns June 30th, #{year + 1} 11:59:59 PM as the end date" do
          end_date = DateTime.parse("June 29th, #{year + 1} 11:59:59 PM")
          expect(term_year.ends_at).to eq end_date
        end
      end
    end
  end

  context 'winter' do
    let(:term) { 'winter' }

    TESTED_YEARS.each do |year|
      context year.to_s do
        let(:year) { year }

        it "Nov 1st, #{year} 00:00:00 AM as the start date" do
          start_date = DateTime.parse("Nov 1st, #{year} 00:00:00 AM")
          expect(term_year.starts_at).to eq start_date
        end

        it "Feb 28th, #{year + 1} 11:59:59 PM as the end date" do
          expect(term_year.ends_at.year).to eq year + 1
          expect(term_year.ends_at.month).to eq 2 # can't compare exact because feb/leap year
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
          end_date = DateTime.parse("June 29th, #{year} 11:59:59 PM")
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

        it "returns April 1st, #{year} 00:00:00 AM as the start date" do
          start_date = DateTime.parse("April 1st, #{year} 00:00:00 AM")
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

  it 'returns the correct visible_term_years' do
    current_year = Time.current.year

    spring_date_time        = DateTime.parse("March 1st, #{current_year}"   )
    spring_summer_date_time = DateTime.parse("June 1st, #{current_year}"    )
    summer_fall_date_time   = DateTime.parse("July 1st, #{current_year}"    )
    fall_date_time          = DateTime.parse("November 1st, #{current_year}")

    expect(TermYear.visible_term_years(spring_date_time)).to eq [
      TermYear.new(:spring, current_year), TermYear.new(:summer, current_year    ),
      TermYear.new(:fall,   current_year),
      TermYear.new(:winter, current_year)
    ]

    expect(TermYear.visible_term_years(spring_summer_date_time)).to eq [
      TermYear.new(:spring, current_year    ), TermYear.new(:summer, current_year ),
      TermYear.new(:fall,   current_year    ), TermYear.new(:winter, current_year )
    ]

    expect(TermYear.visible_term_years(summer_fall_date_time)).to eq [
      TermYear.new(:summer, current_year ), TermYear.new(:fall,   current_year ),
      TermYear.new(:winter, current_year ), TermYear.new(:spring, current_year + 1)
    ]

    expect(TermYear.visible_term_years(fall_date_time)).to eq [
      TermYear.new(:fall,   current_year    ), TermYear.new(:winter, current_year ),
      TermYear.new(:spring, current_year + 1), TermYear.new(:summer, current_year + 1),
    ]
  end
end
