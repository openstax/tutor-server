require 'rails_helper'
require 'vcr_helper'

RSpec.describe OpenStax::Biglearn::V1::LocalQueryClient do

  let!(:client) { OpenStax::Biglearn::V1.new_local_query_client }

  context "delegation to the real client" do

    it "delegates #add_exercises to the real client" do
      expect_any_instance_of(OpenStax::Biglearn::V1::RealClient).to receive(:add_exercises).with("blah")
      client.add_exercises("blah")
    end

    it "delegates #add_pools to the real client" do
      expect_any_instance_of(OpenStax::Biglearn::V1::RealClient).to receive(:add_pools).with("blah")
      client.add_pools("blah")
    end

    it "delegates #combine_pools to the real client" do
      expect_any_instance_of(OpenStax::Biglearn::V1::RealClient).to receive(:combine_pools).with("blah")
      client.combine_pools("blah")
    end
  end

  context "#get_projection_exercises" do

    before(:all) do
      @role = Entity::Role.create!

      @exercises = 3.times.map { FactoryGirl.create(:content_exercise) }

      @first_two_pool = new_pool("first_two", @exercises, [0,1])
      @last_two_pool = new_pool("last_two", @exercises, [1,2])
      @last_one_pool = new_pool("last_one", @exercises, [2])
    end

    it "excludes exercises or not" do
      exclusion_pes = client.get_projection_exercises(
        role: @role, pools: [@first_two_pool, @last_two_pool],
        pool_exclusions: [{pool: @last_one_pool}], count: 3, allow_repetitions: false
      )

      expect(exclusion_pes).to contain_exactly(
        a_string_matching(/#{@exercises[0].url}/),
        a_string_matching(/#{@exercises[1].url}/)
      )

      no_exclusion_pes = client.get_projection_exercises(
        role: @role, pools: [@first_two_pool, @last_two_pool],
        pool_exclusions: [], count: 3, allow_repetitions: false
      )

      expect(no_exclusion_pes).to contain_exactly(
        @exercises[0].url,
        @exercises[1].url,
        @exercises[2].url
      )
    end

    context "when history exists" do
      before(:each) do
        allow(GetHistory).to receive(:[]).with(anything()) {
          Hashie::Mash.new(@role => Hashie::Mash.new(exercise_numbers: [@exercises[0].number]))
        }
      end

      it "excludes that history when repetitions not allowed" do
        pes = client.get_projection_exercises(
          role: @role, pools: [@first_two_pool],
          pool_exclusions: [], count: 2, allow_repetitions: false
        )

        expect(pes).to contain_exactly(@exercises[1].url)
      end

      it "includes that history when repetitions allowed" do
        pes = client.get_projection_exercises(
          role: @role, pools: [@first_two_pool],
          pool_exclusions: [], count: 2, allow_repetitions: true
        )

        expect(pes).to contain_exactly(@exercises[1].url, @exercises[0].url)
      end
    end
  end

  context "#get_clues" do

    before(:all) do
      @all_wrong_role = Entity::Role.create!
      @all_right_role = Entity::Role.create!
      @passing_role = Entity::Role.create!

      exercises = 4.times.map { FactoryGirl.create(:content_exercise) }
      @te_ids = []

      {
        @all_wrong_role => [0, 0, 0, 0],
        @all_right_role => [1, 1, 1, 1],
        @passing_role   => [1, 1, 1, 0]
      }.each do |role, correctness|
        exercises.each_with_index do |exercise, ii|
          te = FactoryGirl.create(:tasks_tasked_exercise,
                                  :with_tasking, tasked_to: role,
                                  free_response: '.',
                                  exercise: exercise)
          @te_ids.push(te.id)
          correctness[ii] == 1 ? te.make_correct! : te.make_incorrect!
        end
      end

      @first_two_pool = new_pool("first_two", exercises, [0,1])
      @all_pool = new_pool("all", exercises, [0,1,2,3])
    end

    it "gives back a hash with one entry per pool" do
      clues = client.get_clues(roles: [@passing_role], pools: [@first_two_pool, @all_pool])
      expect(clues.keys.size).to eq 2
    end

    it "gives increasing clues for increasing correctness" do
      all_wrong_clue = client.get_clues(roles: [@all_wrong_role], pools: [@all_pool])["all"]
      all_right_clue = client.get_clues(roles: [@all_right_role], pools: [@all_pool])["all"]
      passing_clue =   client.get_clues(roles: [@passing_role],   pools: [@all_pool])["all"]

      expect(all_wrong_clue[:value]).to be < passing_clue[:value]
      expect(passing_clue[:value]).to be < all_right_clue[:value]
    end

    it "populates all fields in appropriate ranges" do
      passing_clue =   client.get_clues(roles: [@passing_role],   pools: [@all_pool])["all"]

      expect(passing_clue).to include({
        value: a_value_between(0,1),
        value_interpretation: a_string_matching(/low|medium|high/),
        confidence_interval: [a_value_between(0,1), a_value_between(0,1)],
        confidence_interval_interpretation: a_string_matching(/good|bad/),
        sample_size: 4,
        sample_size_interpretation: 'above',
        unique_learner_count: 1
      })

      expect(passing_clue[:confidence_interval][0]).to be < passing_clue[:confidence_interval][1]
    end

    it "filters to the right tasked exercises" do
      expect(
        client.tasked_exercises_by(pool: @all_pool,
                                   roles: [@all_wrong_role, @all_right_role, @passing_role]).map(&:id)
      ).to contain_exactly(*@te_ids)

      expect(
        client.tasked_exercises_by(pool: @first_two_pool,
                                   roles: [@all_right_role, @passing_role]).map(&:id)
      ).to contain_exactly(*@te_ids[4..5], *@te_ids[8..9])
    end
  end

  def new_pool(uuid, exercises, indices)
    pool = Content::Models::Pool.new(uuid: uuid)
    [indices].flatten.each{|idx| pool.content_exercise_ids << exercises[idx].id}
    pool.wrap
  end

end
