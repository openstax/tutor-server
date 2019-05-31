class BackgroundMigrate
  lev_routine transaction: :no_transaction

  def self.load_rake_tasks_if_needed
    Rails.application.load_tasks unless defined?(Rake::Task) &&
                                        Rake::Task.task_defined?('db:load_config') &&
                                        Rake::Task.task_defined?('db:_dump')
  end

  protected

  def exec(direction, version)
    self.class.load_rake_tasks_if_needed

    Rake::Task['db:load_config'].invoke

    paths = ActiveRecord::Migrator.migrations_paths.map do |path|
      path.sub 'migrate', 'background_migrate'
    end
    ActiveRecord::MigrationContext.new(paths).run(direction.to_sym, version.to_i)

    Rake::Task['db:_dump'].invoke
  end
end
