class BackgroundMigrate
  lev_routine

  protected

  def exec(direction, version)
    Rake::Task["db:load_config"].invoke
    paths = ActiveRecord::Migrator.migrations_paths.map do |path|
      path.sub 'migrate', 'background_migrate'
    end
    ActiveRecord::Migrator.run(direction.to_sym, paths, version.to_i)
    Rake::Task["db:_dump"].invoke
  end
end
