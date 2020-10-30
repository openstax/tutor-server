# frozen_string_literal: true

db_namespace = namespace :db do
  desc 'Runs setup if database does not exist, or runs migrations if it does'
  task prepare: :load_config do
    begin
      ActiveRecord::Base.establish_connection

      # Skipped when no database
      db_namespace[:migrate].invoke
    rescue ActiveRecord::NoDatabaseError
      db_namespace[:setup].invoke
    end
  end
end
