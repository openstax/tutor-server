require 'rails_helper'
require_relative(
  '../../db/background_migrate/20180219163045_add_question_index_to_existing_tasks_tasked_exercises'
)

RSpec.describe AddQuestionIndexToExistingTasksTaskedExercises, type: :migration do
  before(:all) do
    @verbose = ActiveRecord::Migration.verbose
    ActiveRecord::Migration.verbose = false

    @tasked_exercise = FactoryBot.create :tasks_tasked_exercise
  end
  after(:all)  { ActiveRecord::Migration.verbose = @verbose }

  context 'up' do
    before(:all) do
      DatabaseCleaner.start

      ActiveRecord::Base.connection.execute(
        'ALTER TABLE "tasks_tasked_exercises" ALTER "question_index" DROP NOT NULL'
      )
    end
    after(:all)  { DatabaseCleaner.clean }

    before { @tasked_exercise.update_attribute :question_index, nil }

    it 'assigns question_index to tasked_exercises and sets the column to NOT NULL' do
      expect { described_class.new.up }.to(
        change { @tasked_exercise.reload.question_index }.from(nil).to(0)
      )

      expect { @tasked_exercise.update_attribute :question_index, nil }.to(
        raise_error(ActiveRecord::StatementInvalid)
      )
    end
  end

  context 'down' do
    it 'does nothing' do
      expect { described_class.new.down }.not_to change { @tasked_exercise.reload.question_index }

      expect { @tasked_exercise.update_attribute :question_index, nil }.to(
        raise_error(ActiveRecord::StatementInvalid)
      )
    end
  end
end
