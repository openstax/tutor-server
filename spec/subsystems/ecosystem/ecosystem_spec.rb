require 'rails_helper'

module Ecosystem
  describe Ecosystem do

    let!(:valid_uuid)   { ::Ecosystem::Uuid.new }
    let!(:invalid_uuid) { Object.new }

    let!(:valid_book)   { ::Ecosystem::Book.new(strategy: Object.new) }
    let!(:invalid_book) { Object.new }

    let!(:valid_page)   { ::Ecosystem::Page.new(strategy: Object.new) }
    let!(:invalid_page) { Object.new }

    let!(:valid_exercise)   { ::Ecosystem::Exercise.new(strategy: Object.new) }
    let!(:invalid_exercise) { Object.new }

    let(:strategy) {
      double("strategy").tap do |dbl|
        allow(dbl).to receive(:uuid).with(no_args)
                     .and_return(strategy_uuid)

        allow(dbl).to receive(:books).with(no_args)
                     .and_return(strategy_books)

        allow(dbl).to receive(:exercises).with(no_args)
                     .and_return(strategy_exercises)

        allow(dbl).to receive(:reading_core_exercises).with(pages: strategy_expected_pages)
                     .and_return(strategy_reading_core_exercises)

        allow(dbl).to receive(:reading_dynamic_exercises).with(pages: strategy_expected_pages)
                     .and_return(strategy_reading_dynamic_exercises)

        allow(dbl).to receive(:homework_core_exercises).with(pages: strategy_expected_pages)
                     .and_return(strategy_homework_core_exercises)

        allow(dbl).to receive(:homework_dynamic_exercises).with(pages: strategy_expected_pages)
                     .and_return(strategy_homework_dynamic_exercises)

        allow(dbl).to receive(:practice_widget_exercises).with(pages: strategy_expected_pages)
                     .and_return(strategy_practice_widget_exercises)
      end
    }

    let(:strategy_uuid)      { valid_uuid }
    let(:strategy_books)     { [valid_book, valid_book] }
    let(:strategy_exercises) { [valid_exercise, valid_exercise] }

    let(:strategy_expected_pages) { [valid_page, valid_page] }

    let(:strategy_reading_core_exercises)     { [valid_exercise, valid_exercise] }
    let(:strategy_reading_dynamic_exercises)  { [valid_exercise, valid_exercise] }
    let(:strategy_homework_core_exercises)    { [valid_exercise, valid_exercise] }
    let(:strategy_homework_dynamic_exercises) { [valid_exercise, valid_exercise] }
    let(:strategy_practice_widget_exercises)  { [valid_exercise, valid_exercise] }

    let(:ecosystem) { ::Ecosystem::Ecosystem.new(strategy: strategy) }


    context "construction" do
      it "accepts a strategy object" do
        expect{
          ::Ecosystem::Ecosystem.new(strategy: strategy)
        }.to_not raise_error
      end
    end


    context "unique identifier" do
      it "delegates to its strategy" do
        ecosystem.uuid
        expect(strategy).to have_received(:uuid)
      end

      context "strategy returns Ecosystem::Uuid" do
        let(:strategy_uuid) { valid_uuid }

        it "returns the strategy's uuid" do
          uuid = ecosystem.uuid
          expect(uuid).to eq(strategy_uuid)
        end
      end

      context "strategy doesn't return an Ecosystem::Uuid" do
        let!(:strategy_uuid) { invalid_uuid }

        it "raises Ecosystem::StrategyError" do
          expect{
            ecosystem.uuid
          }.to raise_error(::Ecosystem::StrategyError)
        end
      end
    end


    context "fetching books" do
      it "delegates to its strategy" do
        ecosystem.books
        expect(strategy).to have_received(:books)
      end

      context "strategy returns Ecosystem::Books" do
        let(:strategy_books) { [ valid_book, valid_book ] }

        it "returns the strategy's books" do
          books = ecosystem.books
          expect(books).to eq(strategy_books)
        end
      end

      context "strategy doesn't return Ecosystem::Books" do
        let(:strategy_books) { [ valid_book, invalid_book, valid_book ] }

        it "raises Ecosystem::StrategyError" do
          expect{
            ecosystem.books
          }.to raise_error(::Ecosystem::StrategyError)
        end
      end
    end


    context "fetching all exercises" do
      it "delegates to its strategy" do
        ecosystem.exercises
        expect(strategy).to have_received(:exercises)
      end

      context "strategy returns Ecosystem::Exercises" do
        let(:strategy_exercises) { [ valid_exercise, valid_exercise ] }

        it "returns the strategy's exercises" do
          exercises = ecosystem.exercises
          expect(exercises).to eq(strategy_exercises)
        end
      end

      context "strategy doesn't return Ecosystem::Exercises" do
        let(:strategy_exercises) { [ valid_exercise, invalid_exercise, valid_exercise ] }

        it "raises Ecosystem::StrategyError" do
          expect{
            ecosystem.exercises
          }.to raise_error(::Ecosystem::StrategyError)
        end
      end
    end


    context "fetching reading core exercise pool" do
      context "delegation" do
        context "single page" do
          let(:page) { valid_page }
          let(:strategy_expected_pages) { [page] }

          it "delegates to its strategy with the correct pages:" do
            ecosystem.reading_core_exercises(pages: page)
            expect(strategy).to have_received(:reading_core_exercises)
          end
        end

        context "multiple pages" do
          let(:pages) { [valid_page, valid_page] }
          let(:strategy_expected_pages) { pages }

          it "delegates to its strategy with the correct pages:" do
            ecosystem.reading_core_exercises(pages: pages)
            expect(strategy).to have_received(:reading_core_exercises)
          end
        end
      end

      context "valid pages:" do
        let(:pages) { [valid_page, valid_page] }

        context "strategy returns Ecosystem::Exercises" do
          let(:strategy_reading_core_exercises) { [ valid_exercise, valid_exercise ] }

          it "returns the strategy's exercises" do
            exercises = ecosystem.reading_core_exercises(pages: pages)
            expect(exercises).to eq(strategy_reading_core_exercises)
          end
        end

        context "strategy doesn't return Ecosystem::Exercises" do
          let(:strategy_reading_core_exercises) { [ valid_exercise, invalid_exercise, valid_exercise ] }

          it "raises Ecosystem::StrategyError" do
            expect{
              ecosystem.reading_core_exercises(pages: pages)
            }.to raise_error(::Ecosystem::StrategyError)
          end
        end
      end

      context "invalid pages:" do
        let(:pages) { [valid_page, invalid_page, valid_page] }

        it "raises ArgumentError" do
          expect{
            ecosystem.reading_core_exercises(pages: pages)
          }.to raise_error(ArgumentError)
        end
      end
    end


    context "fetching reading dynamic exercise pool" do
      context "delegation" do
        context "single page" do
          let(:page) { valid_page }
          let(:strategy_expected_pages) { [page] }

          it "delegates to its strategy with the correct pages:" do
            ecosystem.reading_dynamic_exercises(pages: page)
            expect(strategy).to have_received(:reading_dynamic_exercises)
          end
        end

        context "multiple pages" do
          let(:pages) { [valid_page, valid_page] }
          let(:strategy_expected_pages) { pages }

          it "delegates to its strategy with the correct pages:" do
            ecosystem.reading_dynamic_exercises(pages: pages)
            expect(strategy).to have_received(:reading_dynamic_exercises)
          end
        end
      end

      context "valid pages:" do
        let(:pages) { [valid_page, valid_page] }

        context "strategy returns Ecosystem::Exercises" do
          let(:strategy_reading_dynamic_exercises) { [ valid_exercise, valid_exercise ] }

          it "returns the strategy's exercises" do
            exercises = ecosystem.reading_dynamic_exercises(pages: pages)
            expect(exercises).to eq(strategy_reading_dynamic_exercises)
          end
        end

        context "strategy doesn't return Ecosystem::Exercises" do
          let(:strategy_reading_dynamic_exercises) { [ valid_exercise, invalid_exercise, valid_exercise ] }

          it "raises Ecosystem::StrategyError" do
            expect{
              ecosystem.reading_dynamic_exercises(pages: pages)
            }.to raise_error(::Ecosystem::StrategyError)
          end
        end
      end

      context "invalid pages:" do
        let(:pages) { [valid_page, invalid_page, valid_page] }

        it "raises ArgumentError" do
          expect{
            ecosystem.reading_dynamic_exercises(pages: pages)
          }.to raise_error(ArgumentError)
        end
      end
    end


    context "fetching homework core exercise pool" do
      context "delegation" do
        context "single page" do
          let(:page) { valid_page }
          let(:strategy_expected_pages) { [page] }

          it "delegates to its strategy with the correct pages:" do
            ecosystem.homework_core_exercises(pages: page)
            expect(strategy).to have_received(:homework_core_exercises)
          end
        end

        context "multiple pages" do
          let(:pages) { [valid_page, valid_page] }
          let(:strategy_expected_pages) { pages }

          it "delegates to its strategy with the correct pages:" do
            ecosystem.homework_core_exercises(pages: pages)
            expect(strategy).to have_received(:homework_core_exercises)
          end
        end
      end

      context "valid pages:" do
        let(:pages) { [valid_page, valid_page] }

        context "strategy returns Ecosystem::Exercises" do
          let(:strategy_homework_core_exercises) { [ valid_exercise, valid_exercise ] }

          it "returns the strategy's exercises" do
            exercises = ecosystem.homework_core_exercises(pages: pages)
            expect(exercises).to eq(strategy_homework_core_exercises)
          end
        end

        context "strategy doesn't return Ecosystem::Exercises" do
          let(:strategy_homework_core_exercises) { [ valid_exercise, invalid_exercise, valid_exercise ] }

          it "raises Ecosystem::StrategyError" do
            expect{
              ecosystem.homework_core_exercises(pages: pages)
            }.to raise_error(::Ecosystem::StrategyError)
          end
        end
      end

      context "invalid pages:" do
        let(:pages) { [valid_page, invalid_page, valid_page] }

        it "raises ArgumentError" do
          expect{
            ecosystem.homework_core_exercises(pages: pages)
          }.to raise_error(ArgumentError)
        end
      end
    end


    context "fetching homework dynamic exercise pool" do
      context "delegation" do
        context "single page" do
          let(:page) { valid_page }
          let(:strategy_expected_pages) { [page] }

          it "delegates to its strategy with the correct pages:" do
            ecosystem.homework_dynamic_exercises(pages: page)
            expect(strategy).to have_received(:homework_dynamic_exercises)
          end
        end

        context "multiple pages" do
          let(:pages) { [valid_page, valid_page] }
          let(:strategy_expected_pages) { pages }

          it "delegates to its strategy with the correct pages:" do
            ecosystem.homework_dynamic_exercises(pages: pages)
            expect(strategy).to have_received(:homework_dynamic_exercises)
          end
        end
      end

      context "valid pages:" do
        let(:pages) { [valid_page, valid_page] }

        context "strategy returns Ecosystem::Exercises" do
          let(:strategy_homework_dynamic_exercises) { [ valid_exercise, valid_exercise ] }

          it "returns the strategy's exercises" do
            exercises = ecosystem.homework_dynamic_exercises(pages: pages)
            expect(exercises).to eq(strategy_homework_dynamic_exercises)
          end
        end

        context "strategy doesn't return Ecosystem::Exercises" do
          let(:strategy_homework_dynamic_exercises) { [ valid_exercise, invalid_exercise, valid_exercise ] }

          it "raises Ecosystem::StrategyError" do
            expect{
              ecosystem.homework_dynamic_exercises(pages: pages)
            }.to raise_error(::Ecosystem::StrategyError)
          end
        end
      end

      context "invalid pages:" do
        let(:pages) { [valid_page, invalid_page, valid_page] }

        it "raises ArgumentError" do
          expect{
            ecosystem.homework_dynamic_exercises(pages: pages)
          }.to raise_error(ArgumentError)
        end
      end
    end


  end
end
