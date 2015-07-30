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
        double("strategy").tap{ |double|
          allow(double).to receive(:books).with(no_args)
                       .and_return(strategy_books)
        }
      }

      let(:ecosystem) {
        Ecosystem.new(strategy: strategy)
      }

      let!(:book_double) {
        double(Ecosystem::Book).tap{ |double|
          allow(double).to receive(:is_a?).with(Ecosystem::Book)
                       .and_return(true)
        }
      }

      context "happy paths" do
        let!(:strategy_books) {
          [book_double]
        }

        it "delegates to its strategy" do
          ecosystem.books
          expect(strategy).to have_received(:books).with(no_args)
        end

        it "returns the strategy's books" do
          expect(ecosystem.books).to eq(strategy_books)
        end

        it "does not raise an error when its strategy returns Ecosystem::Books" do
          expect{
            ecosystem.books
          }.to_not raise_error
        end
      end

      context "error paths" do
        let!(:strategy_books) { [book_double, Object.new, book_double] }

        it "raises error when its strategy does not return Ecosystem::Books" do
          expect{
            ecosystem.books
          }.to raise_error(Ecosystem::StrategyError)
        end
      end
    end

  end
end
