require 'rails_helper'
require 'vcr_helper'

RSpec.describe OpenStax::Exercises::V1::RealClient, type: :external, vcr: VCR_OPTS do

  before(:all) do
    @config = OpenStax::Exercises::V1.configuration
    @client_id = @config.client_id
    @secret = @config.secret
    @config.client_id = nil
    @config.secret = nil
  end

  after(:all) do
    @config.client_id = @client_id
    @config.secret = @secret
  end

  let(:client) { OpenStax::Exercises::V1.real_client }

  context "exercises search" do

    context "single match" do
      it "returns an Exercise matching some content" do
        results = JSON.parse(client.exercises(content: 'WhAt Is KiNeMaTiCs?'))

        expect(results['total_count']).to eq 1
        expect(results['items'].length).to eq 1
      end

      it "returns an Exercise matching a tag" do
        results = JSON.parse(client.exercises(tag: 'k12phys-ch04-ex002'))

        expect(results['total_count']).to eq 1
        expect(results['items'].length).to eq 1
      end
    end

    context "multiple matches" do
      it "returns Exercises matching some content" do
        results = JSON.parse(client.exercises(content: 'FoRcE'))

        expect(results['total_count']).to eq 298
        expect(results['items'].length).to eq 298
      end

      it "returns Exercises matching a tag" do
        results = JSON.parse(client.exercises(tag: 'k12phys-ch04-s01-lo01'))

        expect(results['total_count']).to eq 16
        expect(results['items'].length).to eq 16
      end
    end

    it "sorts by multiple fields in different directions" do
      results = JSON.parse(client.exercises(
        content: 'fOrCe', order_by: 'number DESC, version ASC'
      ))

      expect(results['total_count']).to eq 298
      expect(results['items'].length).to eq 298
      previous_number = Float::INFINITY
      results['items'].each do |item|
        current_number = item['number']
        current_version = item['version']
        expect(current_number < previous_number || \
              (current_number == previous_number && \
                current_version > previous_version)).to eq true
        previous_number = current_number
        previous_version = current_version
      end
    end

  end

end
