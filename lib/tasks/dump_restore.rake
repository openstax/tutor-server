# Tasks for dumping and restoring databases (for development purposes).
#
# Dumped filenames start with the timestamp of the data's latest migration
# file.
#
# When restoring dumps, this code will freak out if the data being
# restored is at a migration beyond what the current checked out code has.
# You can restore any dump generated from an older migration.  The restore
# task runs migrations as the last step to bring the data up to date.
#
# rake db:dump['physics']  makes a filename ending with `_physics.dump`
# rake db:dump             makes a filename ending with `_tutor.dump`
# rake db:restore['phys']  will find a file matching first `phys` exactly,
#                          then /\d+_phys(.dump)?/, then /.*phys.*/
# rake db:restore          defaults the name argument to 'tutor'
#
# To share these, upload dumps to Box (let's all use a consistent directory).
#
# Adapted from https://gist.github.com/hopsoft/56ba6f55fe48ad7f8b90

namespace :db do

  desc "Dumps the database to db/dumps with a name based on the " \
       "provided argument and the latest migration timestamp"
  task :dump, [:name] => :environment do |t, args|
    args ||= {}

    name = args[:name] || Rails.application.class.parent_name.underscore

    dump_file = dump_file(name)

    abort("Failed! The file you are dumping to (#{dump_file}) already exists.") if File.exist?(dump_file)
    dumps_dir.mkdir unless dumps_dir.exist?

    cmd = "pg_dump #{Pgdb.cmd_line_flags.join(' ')} " \
          "--clean --no-owner --no-acl " \
          "--format=c #{Pgdb.name} > #{dump_file}"

    puts cmd
    exec Pgdb.env, cmd
  end

  desc "Restores the database dump from db/dumps with a name matching " \
       "the provided argument.  Runs migrations.  Freaks out if data using " \
       "new schema"
  task :restore, [:name] => :environment do |t, args|
    args ||= {}


    name = args[:name] || app
    cmd = "pg_restore #{Pgdb.cmd_line_flags.join(' ')} " \
          "--clean --create --no-owner --no-acl " \
          "--dbname #{Pgdb.name} #{restore_file(name)}"

    puts cmd
    exec Pgdb.env, "#{cmd} > /dev/null 2>&1"
    Rake::Task["db:migrate"].invoke
  end

  private

  def latest_migration_timestamp
    migration_timestamp(Dir.entries("#{Rails.root}/db/migrate").sort.last)
  end

  def migration_timestamp(filename)
    filename.match(/(\d+)_/)[1]
  end

  def dumps_dir
    Rails.root.join('db', 'dumps')
  end

  def dump_file(name)
    dumps_dir.join("#{latest_migration_timestamp}_#{sanitize_filename(name)}.dump")
  end

  def restore_file(name)
    # The complexity here is trying to find a file that is a reasonable match for the
    # `name` argument.

    available_files = Dir.entries(dumps_dir).sort.reverse

    match = [name, /\d+_#{name}(.dump)?/, /.*#{name}.*/].map do |arg|
      available_files.select{|entry| entry.match(arg)}.tap do |matches|
        abort("Failed! Multiple matching dump files found, please be more specific") if matches.length > 1
      end.first
    end.compact.first

    abort("Failed! Can't find a dump file matching '#{name}'.") if match.nil?
    abort("Failed! The dump you are trying to restore (#{match}) is incompatible with the current schema.") \
      if migration_timestamp(match) > latest_migration_timestamp

    "#{dumps_dir}/#{match}"
  end

  # http://stackoverflow.com/a/10823131
  def sanitize_filename(filename)
    fn = filename.split /(?<=.)\.(?=[^.])(?!.*\.[^.])/m
    fn.map! { |s| s.gsub /[^a-z0-9\-]+/i, '_' }
    fn.join '.'
  end

end
