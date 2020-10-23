task :update_secrets do
  # This is initially set by the EC2 UserData
  # In subsequent runs, it is read from .env
  if ENV['ENVIRONMENT_NAME'].blank?
    puts 'ENVIRONMENT_NAME environment variable missing'

    next
  end

  require 'aws-sdk-ssm'

  secrets = {
    PUMA_MAX_THREADS: 16,
    PUMA_NUM_WORKERS: Etc.nprocessors,
    PUMA_PIDFILE: Rails.root.join('tmp', 'pids'),
    PUMA_PRELOAD_APP: true,
    PUMA_REDIRECT_STDOUT: true,
    PUMA_SOCKET: Rails.root.join('tmp', 'sockets'),
    PUMA_STDERR_LOGFILE: Rails.root.join('log', 'puma.stdout.log'),
    PUMA_STDOUT_LOGFILE: Rails.root.join('log', 'puma.stderr.log')
  }

  client = Aws::SSM::Client.new

  merge_secrets_with_parameters = ->(environment) do
    path = "/#{environment}/tutor/"

    client.get_parameters_by_path(path: path, recursive: true, with_decryption: true).each do |resp|
      resp.parameters.each do |param|
        secrets[param.name.sub(path, '').upcase] = param.value
      end
    end
  end

  merge_secrets_with_parameters.call 'shared'

  merge_secrets_with_parameters.call ENV['ENVIRONMENT_NAME']

  File.open(Rails.root.join('.env'), 'w') do |env|
    secrets.each { |key, value| env.puts "export #{key}=#{value}" }
  end
end
