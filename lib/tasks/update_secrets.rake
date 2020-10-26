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
    PRELOAD_APP: true,
    RAILS_MAX_THREADS: 16,
    SOCKET: Rails.root.join('tmp', 'sockets', 'puma.sock')
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
