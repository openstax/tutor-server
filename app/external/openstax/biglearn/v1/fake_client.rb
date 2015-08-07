class OpenStax::Biglearn::V1::FakeClient

  include Singleton

  #
  # API methods
  #

  def get_clue(roles:, tags:)
    aggregate = rand(0.0..1.0)
    confidence_left  = [aggregate - 0.1, 0.0].max
    confidence_right = [aggregate + 0.1, 1.0].min
    level = aggregate >= 0.8 ? 'high' : (aggregate >= 0.3 ? 'medium' : 'low')
    confidence = ['good', 'bad'].sample
    samples = 6
    threshold = 'above'

    {
      value: aggregate,
      value_interpretation: level,
      confidence_interval: [
        confidence_left,
        confidence_right
      ],
      confidence_interval_interpretation: confidence,
      sample_size: samples,
      sample_size_interpretation: 'above'
    }
  end

  def add_exercises(exercises)
    # Iterate through the exercises, storing each in the store, overwriting
    # any with the same ID

    [exercises].flatten.each do |exercise|
      store['exercises'][exercise.question_id] ||= {}
      store['exercises'][exercise.question_id][exercise.version] = exercise.tags
    end

    save!
  end

  def add_pools(pools)
    # Add the given pools to the store, overwriting any with the same UUID

    result = pools.collect do |pool|
      uuid = SecureRandom.uuid
      store['pools'][uuid] = pool.exercises.collect{ |ex| ex.question_id }
      { 'pool_id' => uuid }
    end

    save!

    result

  end

  def combine_pools(pools)
    # Combine the given pools into one

    pool_uuids = pools.collect{ |pl| pl.uuid }
    question_ids = pool_uuids.collect{ |uuid| store['pools'][uuid] }.flatten.uniq
    uuid = SecureRandom.uuid

    store['pools'][uuid] = question_ids

    save!

    { 'pool_id' => uuid }
  end

  def get_projection_exercises(role:, pools:, count:, difficulty:, allow_repetitions:)
    # Get the pools
    question_ids = pools.collect{ |pool| store['pools'][pool.uuid] }.flatten.uniq

    # Limit the results to the desired number
    results = question_ids.first(count)

    # If we didn't get as many as requested and repetitions are allowed,
    # pad the results, repeat the matches until we have enough, making
    # sure to clip at the desired count in case we go over.
    while (allow_repetitions && results.length < count && question_ids.any?)
      results += question_ids.first(count - results.length)
    end
    results
  end

  # Example conditions: { _and: [ { _or: ['a', 'b', 'c'] }, 'd']  }
  def tags_match_condition?(tags, condition)
    case condition
    when Hash
      if condition.size != 1 then raise IllegalArgument, "too many hash conditions" end
      case condition.first[0]
      when :_and
        condition.first[1].all?{|c| tags_match_condition?(tags, c)}
      when :_or
        condition.first[1].any?{|c| tags_match_condition?(tags, c)}
      else raise NotYetImplemented, "Unknown boolean symbol #{condition.first[0]}"
      end
    when String
      tags.include?(condition)
    else raise IllegalArgument
    end
  end

  #
  # Debugging methods
  #

  def store_exercises_copy
    store['exercises'].clone
  end

  def reload!
    store(true)
  end

  protected

  def store(reload=false)
    # We need to load the store from the DB if
    # (1) we haven't yet done so
    # (2) someone wants us to load it
    # (3) We have loaded it but it is no longer in the DB (which can happen in tests)

    if @fake_store.nil? ||
       reload ||
       ::FakeStore.where(name: 'openstax_biglearn_v1').none?

      @fake_store = ::FakeStore.find_or_create_by(name: 'openstax_biglearn_v1')
    end

    @fake_store.data ||= {}

    @fake_store.data['exercises'] ||= {}
    @fake_store.data['pools'] ||= {}

    @fake_store.data
  end

  def save!
    @fake_store.save! if @fake_store.present?
  end

end
