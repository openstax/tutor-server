require 'rails_helper'

module Content
  RSpec.describe Ecosystem, type: :wrapper do

    let(:valid_id)   { 1 }
    let(:invalid_id) { Object.new }

    let(:valid_book)   { ::Content::Book.new(strategy: Object.new) }
    let(:invalid_book) { Object.new }

    let(:valid_page)   { ::Content::Page.new(strategy: Object.new) }
    let(:invalid_page) { Object.new }

    let(:valid_exercise)   { ::Content::Exercise.new(strategy: Object.new) }
    let(:invalid_exercise) { Object.new }

    let(:valid_pool)   { ::Content::Pool.new(strategy: Object.new) }
    let(:invalid_pool) { Object.new }

    let(:valid_manifest)   { ::Content::Manifest.new(strategy: Object.new) }
    let(:invalid_manifest) { Object.new }

    let(:strategy) {
      double("strategy").tap do |dbl|
        allow(dbl).to receive(:id).with(no_args)
                     .and_return(strategy_id)

        allow(dbl).to receive(:books).with(preload: false)
                     .and_return(strategy_books)

        allow(dbl).to receive(:exercises).with(no_args)
                     .and_return(strategy_exercises)

        allow(dbl).to receive(:reading_dynamic_pools).with(pages: strategy_expected_pages)
                     .and_return(strategy_reading_dynamic_pools)

        allow(dbl).to receive(:reading_context_pools).with(pages: strategy_expected_pages)
                     .and_return(strategy_reading_context_pools)

        allow(dbl).to receive(:homework_core_pools).with(pages: strategy_expected_pages)
                     .and_return(strategy_homework_core_pools)

        allow(dbl).to receive(:homework_dynamic_pools).with(pages: strategy_expected_pages)
                     .and_return(strategy_homework_dynamic_pools)

        allow(dbl).to receive(:practice_widget_pools).with(pages: strategy_expected_pages)
                     .and_return(strategy_practice_widget_pools)

        allow(dbl).to receive(:manifest).with(no_args)
                     .and_return(strategy_manifest)
      end
    }

    let(:strategy_id)        { valid_id }
    let(:strategy_books)     { [valid_book, valid_book] }
    let(:strategy_exercises) { [valid_exercise, valid_exercise] }

    let(:strategy_expected_pages) { [valid_page, valid_page] }

    let(:strategy_reading_dynamic_pools)  { [valid_pool, valid_pool] }
    let(:strategy_reading_context_pools)  { [valid_pool, valid_pool] }
    let(:strategy_homework_core_pools)    { [valid_pool, valid_pool] }
    let(:strategy_homework_dynamic_pools) { [valid_pool, valid_pool] }
    let(:strategy_practice_widget_pools)  { [valid_pool, valid_pool] }
    let(:strategy_manifest)               { valid_manifest }

    let(:ecosystem) { ::Content::Ecosystem.new(strategy: strategy) }


    context "construction" do
      it "accepts a strategy object" do
        expect{
          ::Content::Ecosystem.new(strategy: strategy)
        }.to_not raise_error
      end
    end


    context "id" do
      it "delegates to its strategy" do
        ecosystem.id
        expect(strategy).to have_received(:id)
      end

      context "strategy returns Integer" do
        let(:strategy_id) { valid_id }

        it "returns the strategy's id" do
          id = ecosystem.id
          expect(id).to eq(strategy_id)
        end
      end

      context "strategy doesn't return an Integer" do
        let(:strategy_id) { invalid_id }

        it "raises StrategyError" do
          expect{
            ecosystem.id
          }.to raise_error(StrategyError)
        end
      end
    end


    context "fetching books" do
      it "delegates to its strategy" do
        ecosystem.books
        expect(strategy).to have_received(:books)
      end

      context "strategy returns Content::Books" do
        let(:strategy_books) { [ valid_book, valid_book ] }

        it "returns the strategy's books" do
          books = ecosystem.books
          expect(books).to eq(strategy_books)
        end
      end

      context "strategy doesn't return Content::Books" do
        let(:strategy_books) { [ valid_book, invalid_book, valid_book ] }

        it "raises StrategyError" do
          expect{
            ecosystem.books
          }.to raise_error(StrategyError)
        end
      end
    end


    context "fetching all exercises" do
      it "delegates to its strategy" do
        ecosystem.exercises
        expect(strategy).to have_received(:exercises)
      end

      context "strategy returns Content::Exercises" do
        let(:strategy_exercises) { [ valid_exercise, valid_exercise ] }

        it "returns the strategy's exercises" do
          exercises = ecosystem.exercises
          expect(exercises).to eq(strategy_exercises)
        end
      end

      context "strategy doesn't return Content::Exercises" do
        let(:strategy_exercises) { [ valid_exercise, invalid_exercise, valid_exercise ] }

        it "raises StrategyError" do
          expect{
            ecosystem.exercises
          }.to raise_error(StrategyError)
        end
      end
    end


    context "fetching reading dynamic exercise pool" do
      context "delegation" do
        context "single page" do
          let(:page) { valid_page }
          let(:strategy_expected_pages) { [page] }

          it "delegates to its strategy with the correct pages:" do
            ecosystem.reading_dynamic_pools(pages: page)
            expect(strategy).to have_received(:reading_dynamic_pools)
          end
        end

        context "multiple pages" do
          let(:pages) { [valid_page, valid_page] }
          let(:strategy_expected_pages) { pages }

          it "delegates to its strategy with the correct pages:" do
            ecosystem.reading_dynamic_pools(pages: pages)
            expect(strategy).to have_received(:reading_dynamic_pools)
          end
        end
      end

      context "valid pages:" do
        let(:pages) { [valid_page, valid_page] }

        context "strategy returns Content::Pools" do
          let(:strategy_reading_dynamic_pools) { [ valid_pool, valid_pool ] }

          it "returns the strategy's exercises" do
            pools = ecosystem.reading_dynamic_pools(pages: pages)
            expect(pools).to eq(strategy_reading_dynamic_pools)
          end
        end

        context "strategy doesn't return Content::Exercises" do
          let(:strategy_reading_dynamic_pools) { [ valid_pool, invalid_pool, valid_pool ] }

          it "raises StrategyError" do
            expect{
              ecosystem.reading_dynamic_pools(pages: pages)
            }.to raise_error(StrategyError)
          end
        end
      end

      context "invalid pages:" do
        let(:pages) { [valid_page, invalid_page, valid_page] }

        it "raises TypeError" do
          expect{
            ecosystem.reading_dynamic_pools(pages: pages)
          }.to raise_error(TypeError)
        end
      end
    end


    context "fetching reading try another exercise pool" do
      context "delegation" do
        context "single page" do
          let(:page) { valid_page }
          let(:strategy_expected_pages) { [page] }

          it "delegates to its strategy with the correct pages:" do
            ecosystem.reading_context_pools(pages: page)
            expect(strategy).to have_received(:reading_context_pools)
          end
        end

        context "multiple pages" do
          let(:pages) { [valid_page, valid_page] }
          let(:strategy_expected_pages) { pages }

          it "delegates to its strategy with the correct pages:" do
            ecosystem.reading_context_pools(pages: pages)
            expect(strategy).to have_received(:reading_context_pools)
          end
        end
      end

      context "valid pages:" do
        let(:pages) { [valid_page, valid_page] }

        context "strategy returns Content::Pools" do
          let(:strategy_reading_context_pools) { [ valid_pool, valid_pool ] }

          it "returns the strategy's exercises" do
            pools = ecosystem.reading_context_pools(pages: pages)
            expect(pools).to eq(strategy_reading_context_pools)
          end
        end

        context "strategy doesn't return Content::Exercises" do
          let(:strategy_reading_context_pools) { [ valid_pool, invalid_pool, valid_pool ] }

          it "raises StrategyError" do
            expect{
              ecosystem.reading_context_pools(pages: pages)
            }.to raise_error(StrategyError)
          end
        end
      end

      context "invalid pages:" do
        let(:pages) { [valid_page, invalid_page, valid_page] }

        it "raises TypeError" do
          expect{
            ecosystem.reading_context_pools(pages: pages)
          }.to raise_error(TypeError)
        end
      end
    end


    context "fetching homework core exercise pool" do
      context "delegation" do
        context "single page" do
          let(:page) { valid_page }
          let(:strategy_expected_pages) { [page] }

          it "delegates to its strategy with the correct pages:" do
            ecosystem.homework_core_pools(pages: page)
            expect(strategy).to have_received(:homework_core_pools)
          end
        end

        context "multiple pages" do
          let(:pages) { [valid_page, valid_page] }
          let(:strategy_expected_pages) { pages }

          it "delegates to its strategy with the correct pages:" do
            ecosystem.homework_core_pools(pages: pages)
            expect(strategy).to have_received(:homework_core_pools)
          end
        end
      end

      context "valid pages:" do
        let(:pages) { [valid_page, valid_page] }

        context "strategy returns Content::Pools" do
          let(:strategy_homework_core_pools) { [ valid_pool, valid_pool ] }

          it "returns the strategy's exercises" do
            pools = ecosystem.homework_core_pools(pages: pages)
            expect(pools).to eq(strategy_homework_core_pools)
          end
        end

        context "strategy doesn't return Content::Exercises" do
          let(:strategy_homework_core_pools) { [ valid_pool, invalid_pool, valid_pool ] }

          it "raises StrategyError" do
            expect{
              ecosystem.homework_core_pools(pages: pages)
            }.to raise_error(StrategyError)
          end
        end
      end

      context "invalid pages:" do
        let(:pages) { [valid_page, invalid_page, valid_page] }

        it "raises TypeError" do
          expect{
            ecosystem.homework_core_pools(pages: pages)
          }.to raise_error(TypeError)
        end
      end
    end


    context "fetching homework dynamic exercise pool" do
      context "delegation" do
        context "single page" do
          let(:page) { valid_page }
          let(:strategy_expected_pages) { [page] }

          it "delegates to its strategy with the correct pages:" do
            ecosystem.homework_dynamic_pools(pages: page)
            expect(strategy).to have_received(:homework_dynamic_pools)
          end
        end

        context "multiple pages" do
          let(:pages) { [valid_page, valid_page] }
          let(:strategy_expected_pages) { pages }

          it "delegates to its strategy with the correct pages:" do
            ecosystem.homework_dynamic_pools(pages: pages)
            expect(strategy).to have_received(:homework_dynamic_pools)
          end
        end
      end

      context "valid pages:" do
        let(:pages) { [valid_page, valid_page] }

        context "strategy returns Content::Pools" do
          let(:strategy_homework_dynamic_pools) { [ valid_pool, valid_pool ] }

          it "returns the strategy's exercises" do
            pools = ecosystem.homework_dynamic_pools(pages: pages)
            expect(pools).to eq(strategy_homework_dynamic_pools)
          end
        end

        context "strategy doesn't return Content::Exercises" do
          let(:strategy_homework_dynamic_pools) { [ valid_pool, invalid_pool, valid_pool ] }

          it "raises StrategyError" do
            expect{
              ecosystem.homework_dynamic_pools(pages: pages)
            }.to raise_error(StrategyError)
          end
        end
      end

      context "invalid pages:" do
        let(:pages) { [valid_page, invalid_page, valid_page] }

        it "raises TypeError" do
          expect{
            ecosystem.homework_dynamic_pools(pages: pages)
          }.to raise_error(TypeError)
        end
      end
    end


    context "fetching practice widget exercise pool" do
      context "delegation" do
        context "single page" do
          let(:page) { valid_page }
          let(:strategy_expected_pages) { [page] }

          it "delegates to its strategy with the correct pages:" do
            ecosystem.practice_widget_pools(pages: page)
            expect(strategy).to have_received(:practice_widget_pools)
          end
        end

        context "multiple pages" do
          let(:pages) { [valid_page, valid_page] }
          let(:strategy_expected_pages) { pages }

          it "delegates to its strategy with the correct pages:" do
            ecosystem.practice_widget_pools(pages: pages)
            expect(strategy).to have_received(:practice_widget_pools)
          end
        end
      end

      context "valid pages:" do
        let(:pages) { [valid_page, valid_page] }

        context "strategy returns Content::Pools" do
          let(:strategy_practice_widget_pools) { [ valid_pool, valid_pool ] }

          it "returns the strategy's exercises" do
            pools = ecosystem.practice_widget_pools(pages: pages)
            expect(pools).to eq(strategy_practice_widget_pools)
          end
        end

        context "strategy doesn't return Content::Exercises" do
          let(:strategy_practice_widget_pools) { [ valid_pool, invalid_pool, valid_pool ] }

          it "raises StrategyError" do
            expect{
              ecosystem.practice_widget_pools(pages: pages)
            }.to raise_error(StrategyError)
          end
        end
      end

      context "invalid pages:" do
        let(:pages) { [valid_page, invalid_page, valid_page] }

        it "raises TypeError" do
          expect{
            ecosystem.practice_widget_pools(pages: pages)
          }.to raise_error(TypeError)
        end
      end
    end


    context "generating a manifest" do
      context "delegation" do
        let(:manifest) { valid_manifest }
        let(:strategy_expected_manifest) { manifest }

        it "delegates to its strategy" do
          ecosystem.manifest
          expect(strategy).to have_received(:manifest)
        end
      end

      context "strategy returns Content::Manifest" do
        let(:strategy_manifest) { valid_manifest }

        it "returns the strategy's manifest" do
          manifest = ecosystem.manifest
          expect(manifest).to eq(strategy_manifest)
        end
      end

      context "strategy doesn't return Content::Manifest" do
        let(:strategy_manifest) { invalid_manifest }

        it "raises StrategyError" do
          expect{
            ecosystem.manifest
          }.to raise_error(StrategyError)
        end
      end
    end


  end
end
