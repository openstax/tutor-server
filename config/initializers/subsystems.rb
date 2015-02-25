def require_glob(glob)
  # puts "===== glob = #{glob} ====="
  full_glob = File.join(Rails.root, glob)
  Dir[full_glob].each do |file|
    # puts "=== requiring #{file} ==="
    ActiveSupport.require_or_load file
  end
end

require_glob "app/subsystems/*_ss/*.rb"
require_glob "app/subsystems/*_ss/**/*.rb"
require_glob "app/subsystems/**/domain/*.rb"
