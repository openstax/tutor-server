task :update_secrets do
  # This is initially set by the EC2 UserData
  # In subsequent runs, it is read from .env
  if ENV['ENVIRONMENT_NAME'].blank?
    puts 'ENVIRONMENT_NAME environment variable missing'

    next
  end

  require 'aws-sdk-ssm'

  # Rails/puma default settings
  secrets = {
    ENVIRONMENT_NAME: ENV['ENVIRONMENT_NAME'],
    PRELOAD_APP: true,
    RAILS_MAX_THREADS: 16,
    RDS_SECRET_ID: ENV['RDS_SECRET_ID'],
    SOCKET: Rails.root.join('tmp', 'sockets', 'puma.sock')
  }.stringify_keys

  client = Aws::SSM::Client.new

  merge_secrets_with_parameters = ->(environment) do
    path = "/#{environment}/#{Rails.application.class.parent_name.underscore.dasherize}/"

    client.get_parameters_by_path(path: path, recursive: true, with_decryption: true).each do |resp|
      resp.parameters.each do |param|
        secrets[param.name.sub(path, '').upcase] = param.value
      end
    end
  end

  merge_secrets_with_parameters.call 'shared'

  merge_secrets_with_parameters.call secrets['ENVIRONMENT_NAME']

  # Used in the migration stack to fetch the RDS superuser credentials from the secretsmanager
  # and create the application role
  unless secrets['RDS_SECRET_ID'].blank?
    require 'aws-sdk-secretsmanager'

    rds_secret = JSON.parse(
      Aws::SecretsManager::Client.new.get_secret_value(
        secret_id: secrets['RDS_SECRET_ID']
      ).secret_string
    )

    # Save the superuser credentials for later use
    secrets['RDS_SUPERUSER_USERNAME'] = rds_secret['username']
    secrets['RDS_SUPERUSER_PASSWORD'] = rds_secret['password']

    # Create the application role if needed

    # Override the connection info to use the new secrets,
    # postgres database and the superuser credentials
    database_configuration = Rails.configuration.database_configuration[Rails.env].merge(
      {
        host: secrets['RDS_HOST'],
        port: secrets['RDS_PORT'],
        username: secrets['RDS_SUPERUSER_USERNAME'],
        password: secrets['RDS_SUPERUSER_PASSWORD'],
        database: 'postgres'
      }.stringify_keys
    )
    ActiveRecord::Base.establish_connection database_configuration

    # https://stackoverflow.com/a/55954480
    ActiveRecord::Base.connection.execute <<~SQL
      DO $$
        BEGIN
          CREATE USER #{secrets['RDS_USERNAME']} CREATEDB PASSWORD '#{secrets['RDS_PASSWORD']}';
          EXCEPTION
            WHEN DUPLICATE_OBJECT THEN RAISE NOTICE '%, skipping', SQLERRM USING ERRCODE = SQLSTATE;
        END
      $$;
    SQL

    ActiveRecord::Base.remove_connection
  end

  File.open(Rails.root.join('.env'), 'w') do |env|
    secrets.each { |key, value| env.puts "export #{key}=#{value}" unless value.nil? }
  end
end
