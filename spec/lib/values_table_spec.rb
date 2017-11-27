require 'rails_helper'

RSpec.describe ValuesTable, type: :lib do
  before(:all) do
    1.upto(5).each do |number|
      1.upto(5).each do |version|
        instance_variable_set "@exercise_#{number}_#{version}",
                              FactoryBot.create(:content_exercise, number: number, version: version)
      end
    end
  end

  let(:chosen_exercises)     { [ @exercise_2_2, @exercise_2_3, @exercise_3_4 ] }
  let(:numbers_and_versions) { chosen_exercises.map { |ex| ex.uid.split('@').map(&:to_i) } }
  let(:join_sql)         do
    <<-JOIN_SQL.strip_heredoc
      INNER JOIN (#{described_class.new(numbers_and_versions)}) AS "values" ("number", "version")
        ON "content_exercises"."number" = "values"."number"
          AND "content_exercises"."version" = "values"."version"
    JOIN_SQL
  end

  it 'generates valid SQL for a values table that can be used in a join' do
    expect(Content::Models::Exercise.joins(join_sql)).to match_array(chosen_exercises)
  end
end
