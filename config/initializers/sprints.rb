if Rails.env.development? || Rails.env.test?
  Dir.glob("#{Rails.root}/lib/sprint/**/*.rb").each { |f| require f }
end