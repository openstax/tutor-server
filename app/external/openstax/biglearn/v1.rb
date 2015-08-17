module OpenStax::Biglearn::V1

  #
  # API Wrappers
  #

  def self.get_clue(roles:, tags:)
    tags = [tags].flatten.compact
    roles = [roles].flatten.compact

    clue = client.get_clue(roles: roles, tags: tags) || {}
  end

  def self.add_exercises(exercises)
    client.add_exercises(exercises)
  end

  def self.add_pools(pools)
    uuids = client.add_pools(pools)
    pools.each_with_index{ |pool, ii| pool.uuid = uuids[ii] }
    pools
  end

  def self.combine_pools(pools)
    OpenStax::Biglearn::V1::Pool.new(uuid: client.combine_pools(pools))
  end

  # Returns recommended exercises
  #
  # tag_search: a hash describing a boolean search on tags;
  #             exercises that match this search are candidates
  #             to be returned.
  #   Ex:
  #     { _and: [ { _or: ['a', 'b', 'c'] }, 'd']  }
  #
  def self.get_projection_exercises(role:, pools: nil, tag_search: nil,
                                    count: 1, difficulty: 0.5, allow_repetitions: true)
    exercises = client.get_projection_exercises(role: role, pools: pools, tag_search: tag_search,
                                                count: count, difficulty: difficulty,
                                                allow_repetitions: allow_repetitions)

    num_exercises = (exercises || []).size

    if num_exercises != count
      Rails.logger.warn {
        "Biglearn.get_projection_exercises only returned #{num_exercises} of #{count} " +
        "requested exercises [role: #{role}, pools: #{(pools || []).collect{ |pl| pl.uuid }}, " +
        "tag_search: #{tag_search}, difficulty: #{difficulty}, " +
        "allow_repetitions: #{allow_repetitions}] exercises = #{exercises}"
      }
    end

    exercises
  end

  #
  # Configuration
  #

  def self.configure
    yield configuration
  end

  def self.configuration
    @configuration ||= Configuration.new
  end

  # Accessor for the fake client, which has some extra fake methods on it
  def self.fake_client
    FakeClient.instance
  end

  def self.real_client
    RealClient.new(configuration)
  end

  def self.use_real_client
    @client = real_client
  end

  def self.use_fake_client
    @client = fake_client
  end

  private

  def self.client
    begin
      @client ||= real_client
    rescue StandardError => error
      raise ClientError.new("initialization failure", error)
    end
  end

end
