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

    context "fetching books" do
      let(:strategy) {
        double("strategy").tap{ |dbl|
          allow(dbl).to receive(:books).with(no_args)
                       .and_return(strategy_books)
        }
      }

      let(:ecosystem) {
        Ecosystem.new(strategy: strategy)
      }

      context "happy paths" do
        context "strategy returns Ecosystem::Books" do
          let!(:strategy_books) {
            [ Ecosystem::Book.new(strategy: Object.new),
              Ecosystem::Book.new(strategy: Object.new) ]
          }

          it "delegates to its strategy" do
            ecosystem.books
            expect(strategy).to have_received(:books).with(no_args)
          end

          it "returns the strategy's books" do
            expect(ecosystem.books).to eq(strategy_books)
          end
        end
      end

      context "error paths" do
        context "strategy doesn't return Ecosystem::Books" do
          let!(:strategy_books) {
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
