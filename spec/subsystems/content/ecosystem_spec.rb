require 'rails_helper'

module Content
  describe Ecosystem do

    context "construction" do
      it "accepts a strategy object" do
        expect{
          Ecosystem.new(strategy: Object.new)
        }.to_not raise_error
      end
    end

    context "unique identifier" do
      let(:ecosystem) {
        Ecosystem.new(strategy: strategy)
      }

      let(:strategy) {
        double("strategy").tap{ |dbl|
          allow(dbl).to receive(:uuid).with(no_args)
                       .and_return(uuid)
        }
      }

      let(:uuid) { Ecosystem::Uuid.new }

      context "delegation" do
        it "delegates to its strategy" do
          ecosystem.uuid
          expect(strategy).to have_received(:uuid).with(no_args)
        end

        context "strategy returns Ecosystem::Uuid" do
          it "returns the strategy's uuid" do
            expect(ecosystem.uuid).to eq(uuid)
          end
        end

        context "strategy doesn't return an Ecosystem::Uuid" do
          let(:uuid) { Object.new }

          it "raises Ecosystem::StrategyError" do
            expect{
              ecosystem.uuid
            }.to raise_error(Ecosystem::StrategyError)
          end
        end
      end
    end

    context "fetching books" do
      let(:ecosystem) {
        Ecosystem.new(strategy: strategy)
      }

      let(:strategy) {
        double("strategy").tap{ |dbl|
          allow(dbl).to receive(:books).with(no_args)
                       .and_return(strategy_books)
        }
      }

      let(:strategy_books) {
        [ Ecosystem::Book.new(strategy: Object.new),
          Ecosystem::Book.new(strategy: Object.new) ]
      }

      context "delegation" do
        it "delegates to its strategy" do
          ecosystem.books
          expect(strategy).to have_received(:books).with(no_args)
        end

        context "strategy returns Ecosystem::Books" do
          it "returns the strategy's books" do
            expect(ecosystem.books).to eq(strategy_books)
          end
        end

        context "strategy doesn't return Ecosystem::Books" do
          let(:strategy_books) {
            [ Ecosystem::Book.new(strategy: Object.new),
              Object.new,
              Ecosystem::Book.new(strategy: Object.new) ]
          }

          it "raises Ecosystem::StrategyError" do
            expect{
              ecosystem.books
            }.to raise_error(Ecosystem::StrategyError)
          end
        end
      end
    end

  end
end
