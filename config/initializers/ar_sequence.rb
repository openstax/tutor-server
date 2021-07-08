AR::Sequence::Adapter.class_exec do
  def check_sequences
    select_all(
      <<~SELECT_SQL
        SELECT *
        FROM information_schema.sequences
        WHERE NOT sequence_name ILIKE '%_id_seq'
        ORDER BY sequence_name
      SELECT_SQL
    ).to_a
  end
end
