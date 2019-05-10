require 'rails_helper'
require 'rake'

RSpec.describe BackgroundMigrate, type: :routine do
  let(:direction) { ['up', 'down'].sample }
  let(:version)   { Time.current.strftime("%Y%m%d%H%M%S") }

  before(:all)    { BackgroundMigrate.load_rake_tasks_if_needed }

  it 'calls ActiveRecord::MigrationContext.run with the correct args and the db:_dump rake task' do
    Rake::Task['db:load_config'].invoke
    expect(Rake::Task['db:load_config']).to receive(:invoke)

    paths = ActiveRecord::Migrator.migrations_paths.map do |path|
      path.sub 'migrate', 'background_migrate'
    end

    expect(ActiveRecord::MigrationContext).to receive(:new).and_call_original
    expect_any_instance_of(ActiveRecord::MigrationContext).to(
      receive(:run).with(direction.to_sym, version.to_i)
    )

    expect(Rake::Task['db:_dump']).to receive(:invoke)

    described_class.call direction, version
  end
end
