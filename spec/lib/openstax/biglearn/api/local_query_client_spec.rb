require 'rails_helper'
require 'vcr_helper'

RSpec.describe OpenStax::Biglearn::Api::LocalQueryClient do

  context "delegation to the real client" do
    let(:client) { OpenStax::Biglearn::Api.new_local_query_client_with_real }

    it "delegates #add_exercises to the real client" do
      expect_any_instance_of(OpenStax::Biglearn::Api::RealClient).to receive(:add_exercises).with("blah")
      client.add_exercises("blah")
    end

    it "delegates #add_pools to the real client" do
      expect_any_instance_of(OpenStax::Biglearn::Api::RealClient).to receive(:add_pools).with("blah")
      client.add_pools("blah")
    end

    it "delegates #combine_pools to the real client" do
      expect_any_instance_of(OpenStax::Biglearn::Api::RealClient).to receive(:combine_pools).with("blah")
      client.combine_pools("blah")
    end
  end

  it "has a name depending on the wrapped client" do
    expect(OpenStax::Biglearn::Api.new_local_query_client_with_real.name).to eq :local_query_with_real
    expect(OpenStax::Biglearn::Api.new_local_query_client_with_fake.name).to eq :local_query_with_fake
  end

  context "#get_projection_exercises" do
    let(:client) { OpenStax::Biglearn::Api.new_local_query_client_with_real }

    before(:each) do
      @role = FactoryGirl.create :entity_role

      @exercises = 3.times.map { FactoryGirl.create(:content_exercise) }

      @first_two_pool = new_pool("first_two", @exercises, [0,1])
      @last_two_pool = new_pool("last_two", @exercises, [1,2])
      @last_one_pool = new_pool("last_one", @exercises, [2])
    end

    it "excludes exercises or not" do
      exclusion_pes = client.get_projection_exercises(
        role: @role, pool_uuids: [@first_two_pool, @last_two_pool].map(&:uuid),
        pool_exclusions: [{pool: @last_one_pool}], count: 3, allow_repetitions: false
      )

      expect(exclusion_pes).to contain_exactly(
        a_string_matching(/#{@exercises[0].url}/),
        a_string_matching(/#{@exercises[1].url}/)
      )

      no_exclusion_pes = client.get_projection_exercises(
        role: @role, pool_uuids: [@first_two_pool, @last_two_pool].map(&:uuid),
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
          role: @role, pool_uuids: [@first_two_pool.uuid],
          pool_exclusions: [], count: 2, allow_repetitions: false
        )

        expect(pes).to contain_exactly(@exercises[1].url)
      end

      it "includes that history when repetitions allowed" do
        pes = client.get_projection_exercises(
          role: @role, pool_uuids: [@first_two_pool.uuid],
          pool_exclusions: [], count: 2, allow_repetitions: true
        )

        expect(pes).to contain_exactly(@exercises[1].url, @exercises[0].url)
      end
    end
  end

  context "#get_clues" do
    let(:client) { OpenStax::Biglearn::Api.new_local_query_client_with_real }

    before(:all) do
      @all_wrong_role = FactoryGirl.create :entity_role
      @all_right_role = FactoryGirl.create :entity_role
      @passing_role   = FactoryGirl.create :entity_role

      @exercises = 4.times.map { FactoryGirl.create(:content_exercise) }

      @role_map = {
        @all_wrong_role => [0, 0, 0, 0],
        @all_right_role => [1, 1, 1, 1],
        @passing_role   => [1, 1, 1, 0]
      }

      @te_ids = @role_map.flat_map do |role, correctness|
        @exercises.each_with_index.map do |exercise, ii|
          te = FactoryGirl.create(:tasks_tasked_exercise,
                                  :with_tasking, tasked_to: role,
                                  free_response: '.',
                                  exercise: exercise)
          correctness[ii] == 1 ? te.make_correct! : te.make_incorrect!
          te.task_step.complete.save!
          te.id
        end
      end

      @first_two_pool = new_pool("first_two", @exercises, [0,1])
      @all_pool = new_pool("all", @exercises, [0,1,2,3])
    end

    it "gives back a hash with one entry per pool" do
      clues = client.get_clues(
        roles: [@passing_role], pool_uuids: [@first_two_pool, @all_pool].map(&:uuid)
      )
      expect(clues.keys.size).to eq 2
    end

    it "gives increasing clues for increasing correctness" do
      all_wrong_clue = client.get_clues(
        roles: [@all_wrong_role], pool_uuids: [@all_pool.uuid]
      )["all"]
      all_right_clue = client.get_clues(
        roles: [@all_right_role], pool_uuids: [@all_pool.uuid]
      )["all"]
      passing_clue = client.get_clues(roles: [@passing_role], pool_uuids: [@all_pool.uuid])["all"]

      expect(all_wrong_clue[:value]).to be < passing_clue[:value]
      expect(passing_clue[:value]).to be < all_right_clue[:value]
    end

    it "populates all fields in appropriate ranges" do
      passing_clue = client.get_clues(roles: [@passing_role], pool_uuids: [@all_pool.uuid])["all"]

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
      roles = [@all_wrong_role, @all_right_role, @passing_role]
      individual_all_tes = client.completed_tasked_exercises_by(
        pool_uuids: [@all_pool.uuid],
        roles: roles
      )
      expect(individual_all_tes[@all_pool.uuid].keys).to contain_exactly(*roles.map(&:id))
      expect(individual_all_tes[@all_pool.uuid].values.flatten.map(&:id)).to(
        contain_exactly(*@te_ids)
      )

      roles = [@all_right_role, @passing_role]
      individual_first_two_tes = client.completed_tasked_exercises_by(
        pool_uuids: [@first_two_pool.uuid],
        roles: roles
      )
      expect(individual_first_two_tes[@first_two_pool.uuid].keys).to(
        contain_exactly(*roles.map(&:id))
      )
      expect(individual_first_two_tes[@first_two_pool.uuid].values.flatten.map(&:id)).to(
        contain_exactly(*@te_ids[4..5], *@te_ids[8..9])
      )

      roles = [@all_wrong_role, @all_right_role, @passing_role]
      combined_all_tes = client.completed_tasked_exercises_by(
        pool_uuids: [@all_pool.uuid, @first_two_pool.uuid],
        roles: roles
      )
      expect(combined_all_tes[@all_pool.uuid].keys).to contain_exactly(*roles.map(&:id))
      expect(combined_all_tes[@all_pool.uuid].values.flatten).to(
        contain_exactly *individual_all_tes[@all_pool.uuid].values.flatten
      )

      roles = [@all_right_role, @passing_role]
      combined_first_two_tes = client.completed_tasked_exercises_by(
        pool_uuids: [@all_pool.uuid, @first_two_pool.uuid],
        roles: roles
      )
      expect(combined_first_two_tes[@first_two_pool.uuid].keys).to contain_exactly(*roles.map(&:id))
      expect(combined_first_two_tes[@first_two_pool.uuid].values.flatten).to(
        contain_exactly *individual_first_two_tes[@first_two_pool.uuid].values.flatten
      )
    end

    it "filters to the right tasked exercises even with old and new exercises" do
      new_exercises = @exercises.map do |exercise|
        FactoryGirl.create(:content_exercise, number: exercise.number)
      end

      new_te_ids = @role_map.flat_map do |role, correctness|
        new_exercises.each_with_index.map do |exercise, ii|
          te = FactoryGirl.create(:tasks_tasked_exercise,
                                  :with_tasking, tasked_to: role,
                                  free_response: '.',
                                  exercise: exercise)
          correctness[ii] == 1 ? te.make_correct! : te.make_incorrect!
          te.task_step.complete.save!
          te.id
        end
      end

      new_first_two_pool = new_pool("new_first_two", new_exercises, [0,1])
      new_all_pool = new_pool("new_all", new_exercises, [0,1,2,3])

      roles = [@all_wrong_role, @all_right_role, @passing_role]
      new_all_pool_tes = client.completed_tasked_exercises_by(
        pool_uuids: [new_all_pool.uuid], roles: roles
      )[new_all_pool.uuid]
      expect(new_all_pool_tes.keys).to contain_exactly(*roles.map(&:id))
      expect(new_all_pool_tes.values.flatten.map(&:id)).to contain_exactly(*@te_ids, *new_te_ids)

      roles = [@all_right_role, @passing_role]
      new_first_two_pool_tes = client.completed_tasked_exercises_by(
        pool_uuids: [new_first_two_pool.uuid], roles: roles
      )[new_first_two_pool.uuid]
      expect(new_first_two_pool_tes.keys).to contain_exactly(*roles.map(&:id))
      expect(new_first_two_pool_tes.values.flatten.map(&:id)).to(
        contain_exactly(*@te_ids[4..5], *@te_ids[8..9], *new_te_ids[4..5], *new_te_ids[8..9])
      )
    end
  end

  def new_pool(uuid, exercises, indices)
    pool = FactoryGirl.build(:content_pool, uuid: uuid)
    # pool = Content::Models::Pool.homework_dynamic.new(uuid: uuid)
    [indices].flatten.each{|idx| pool.content_exercise_ids << exercises[idx].id}
    pool.save!
    OpenStax::Biglearn::Api::Pool.new(uuid: uuid)
  end

end
