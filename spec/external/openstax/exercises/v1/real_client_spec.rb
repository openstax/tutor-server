require 'rails_helper'
require 'vcr_helper'

RSpec.describe OpenStax::Exercises::V1::RealClient, :vcr => VCR_OPTS do

  let(:exercise_1_hash) {
    { "uid" => "11@1",
      "number" => 11,
      "version" => 1,
      "published_at" => "2015-02-27T00:07:37.490Z",
      "editors" => [],
      "authors" => [],
      "copyright_holders" => [],
      "derived_from" => [],
      "attachments" => [],
      "tags" => ["tag1","tag2"],
      "title" => "Lorem ipsum",
      "stimulus_html" => "",
      "questions" => [
        { "stimulus_html" => "",
          "stem_html" => "Consectetur adipiscing elit",
          "answers" => [
            { "content_html" => "Sed do eiusmod tempor" }
          ],
          "hints" => [],
          "formats" => [],
          "combo_choices" => []
        }
      ]
    }
  }

  let(:exercise_2_hash) {
    { "uid" => "12@1",
      "number" => 12,
      "version" => 1,
      "published_at" => "2015-02-27T00:07:37.501Z",
      "editors" => [],
      "authors" => [],
      "copyright_holders" => [],
      "derived_from" => [],
      "attachments" => [],
      "tags" => ["tag2","tag3"],
      "title" => "Dolorem ipsum",
      "stimulus_html" => "",
      "questions" => [
        { "stimulus_html" => "",
          "stem_html" => "Consectetur adipisci velit",
          "answers" => [
            { "content_html" => "Sed quia non numquam" }
          ],
          "hints" => [],
          "formats" => [],
          "combo_choices" => []
        }
      ]
    }
  }

  let!(:configuration) {
    c = OpenStax::Exercises::V1::Configuration.new
    c.server_url = 'http://localhost:3000'
    c
  }

  let!(:client) { OpenStax::Exercises::V1::RealClient.new configuration }

  context "exercises search" do

    context "single match" do
      it "returns an Exercise matching some content" do
        results = JSON.parse(client.exercises(content: 'aDiPiScInG eLiT'))

        expect(results['total_count']).to eq(1)
        expect(results['items']).to eq([exercise_1_hash])
      end

      it "returns an Exercise matching a tag" do
        results = JSON.parse(client.exercises(tag: 'tAg1'))

        expect(results['total_count']).to eq(1)
        expect(results['items']).to eq([exercise_1_hash])
      end
    end

    context "multiple matches" do
      it "returns Exercises matching some content" do
        results = JSON.parse(client.exercises(content: 'AdIpIsCi'))

        expect(results['total_count']).to eq(2)
        expect(results['items']).to eq([exercise_1_hash, exercise_2_hash])
      end

      it "returns Exercises matching a tag" do
        results = JSON.parse(client.exercises(tag: 'TaG2'))

        expect(results['total_count']).to eq(2)
        expect(results['items']).to eq([exercise_1_hash, exercise_2_hash])
      end
    end

    it "sorts by multiple fields in different directions" do
      results = JSON.parse(client.exercises(
        content: 'aDiPiScI', order_by: 'number DESC, version ASC'
      ))

      expect(results['total_count']).to eq(2)
      expect(results['items']).to eq([exercise_2_hash, exercise_1_hash])
    end

  end

end
