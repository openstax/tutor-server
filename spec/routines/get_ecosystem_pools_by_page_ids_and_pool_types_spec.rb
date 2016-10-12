require 'rails_helper'

RSpec.describe GetEcosystemPoolsByPageIdsAndPoolTypes, type: :routine do
  let(:content_page_1) { FactoryGirl.create :content_page }
  let(:content_page_2) { FactoryGirl.create :content_page, chapter: content_page_1.chapter }
  let(:content_page_3) { FactoryGirl.create :content_page, chapter: content_page_1.chapter }

  let!(:page_1) {
    strategy = ::Content::Strategies::Direct::Page.new(content_page_1)
    ::Content::Page.new(strategy: strategy)
  }
  let!(:page_2) {
    strategy = ::Content::Strategies::Direct::Page.new(content_page_2)
    ::Content::Page.new(strategy: strategy)
  }
  let!(:page_3) {
    strategy = ::Content::Strategies::Direct::Page.new(content_page_3)
    ::Content::Page.new(strategy: strategy)
  }

  let(:ecosystem) { page_1.chapter.book.ecosystem }

  context "when page_ids are not given" do
    context "when pool_types are not given" do
      it "returns a map of pool_types for all pools in the given ecosystem" do
        pools_map = described_class[ecosystem: ecosystem]

        pools = [page_1, page_2, page_3].flat_map do |page|
          [page.reading_dynamic_pool, page.reading_context_pool, page.homework_core_pool,
           page.homework_dynamic_pool, page.practice_widget_pool,
           page.concept_coach_pool, page.all_exercises_pool]
        end

        expect(Set.new pools_map.keys).to eq Set.new Content::Pool.pool_types
        expect(Set.new pools_map.values.flatten).to eq Set.new pools
      end
    end

    context "when pool_types are given" do
      let(:pool_types) { ['reading_dynamic', 'homework_core'] }

      it "returns a map with the given pool_types for the relevant pools in the given ecosystem" do
        pools_map = described_class[ecosystem: ecosystem, pool_types: pool_types]

        pools = [page_1, page_2, page_3].flat_map do |page|
          [page.reading_dynamic_pool, page.homework_core_pool]
        end

        expect(Set.new pools_map.keys).to eq Set.new pool_types
        expect(Set.new pools_map.values.flatten).to eq Set.new pools
      end
    end
  end

  context "when page_ids are given" do
    let(:pages) { [page_1, page_2] }

    context "when pool_types are not given" do
      it "returns a map of pool_types for all pools in the given pages" do
        pools_map = described_class[ecosystem: ecosystem, page_ids: pages.map(&:id)]

        pools = pages.flat_map do |page|
          [page.reading_dynamic_pool, page.reading_context_pool, page.homework_core_pool,
           page.homework_dynamic_pool, page.practice_widget_pool,
           page.concept_coach_pool, page.all_exercises_pool]
        end

        expect(Set.new pools_map.keys).to eq Set.new Content::Pool.pool_types
        expect(Set.new pools_map.values.flatten).to eq Set.new pools
      end
    end

    context "when pool_types are given" do
      let(:pool_types) { ['reading_dynamic', 'homework_core'] }

      it "returns a map with the given pool_types for the relevant pools in the given pages" do
        pools_map = described_class[ecosystem: ecosystem,
                                    page_ids: pages.map(&:id),
                                    pool_types: pool_types]

        pools = pages.flat_map do |page|
          [page.reading_dynamic_pool, page.homework_core_pool]
        end

        expect(Set.new pools_map.keys).to eq Set.new pool_types
        expect(Set.new pools_map.values.flatten).to eq Set.new pools
      end
    end
  end
end
