guard :rspec, cmd:"bin/spring rspec" do
  watch(%r{^spec/.+_spec\.rb$})
  watch(%r{^app/(.+)\.rb$})                           { |m| "spec/#{m[1]}_spec.rb" }
  watch(%r{^lib/(.+)\.rb$})                           { |m| "spec/lib/#{m[1]}_spec.rb" }
  watch(%r{^app/controllers/(.+)_(controller)\.rb$})  { |m| ["spec/controllers/#{m[1]}_#{m[2]}_spec.rb", "spec/features/#{m[1]}_spec.rb"] }

end
