class OpenStax::Biglearn::Sparfa::FakeClient < OpenStax::Biglearn::FakeClient
  QUESTIONS_PER_LEARNER = 100

  # ecosystem_matrix_uuid is the UUID of an ecosystem matrix obtained from Biglearn Scheduler
  # students is an array of CourseMembership::Models::Student

  # Retrieves the SPARFA ecosystem matrix with the given ecosystem_matrix_uuid
  # optionally filtered to the given students
  # Requests is an array of hashes containing :ecosystem_matrix_uuid
  # and optionally :students and/or :responded_before
  def fetch_ecosystem_matrices(requests)
    requests.map do |request|
      student_uuids = request.fetch(:students, []).map(&:uuid)
      nl = student_uuids.size
      nq = rand 10000
      nc = rand 500
      g_row = (QUESTIONS_PER_LEARNER*nl).times.map { rand nq }

      request.slice(:request_uuid, :ecosystem_matrix_uuid, :responded_before).merge(
        ecosystem_uuid: SecureRandom.uuid,
        L_ids: student_uuids,
        Q_ids: nq.times.map { SecureRandom.uuid },
        C_ids: nc.times.map { SecureRandom.uuid },
        d_data: nq.times.map(&:rand),
        W_data: nq.times.map(&:rand),
        W_row: nq.times.map { rand nc },
        W_col: (0..nq-1).to_a,
        H_mask_data: [ true ] * nq,
        H_mask_row: nq.times.map { rand nc },
        H_mask_col: (0..nq-1).to_a,
        G_data: [ true ] * (QUESTIONS_PER_LEARNER*nl),
        G_row: g_row,
        G_col: (0..nl-1).to_a * QUESTIONS_PER_LEARNER,
        G_mask_data: [ true ] * (QUESTIONS_PER_LEARNER*nl),
        G_mask_row: g_row,
        G_mask_col: (0..nl-1).to_a * QUESTIONS_PER_LEARNER,
        U_data: nq.times.map(&:rand),
        U_row: (QUESTIONS_PER_LEARNER*nl).times.map { rand nc },
        U_col: (0..nl-1).to_a * QUESTIONS_PER_LEARNER,
        algorithm_name: ['local_query', 'biglearn_sparfa'].sample,
        exercise_uuids: rand(10000).times.map { SecureRandom.uuid },
        superseded_at: Time.current - 1.week unless request[:responded_before].nil?
      }
    end
  end
end
