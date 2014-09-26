desc "Initializes the config/secrets.yml file from the example file"
file 'config/secrets.yml' => 'config/secrets.yml.example' do
  cp 'config/secrets.yml.example', 'config/secrets.yml'
end

Rake::Task[:spec].enhance [:'config/secrets.yml']