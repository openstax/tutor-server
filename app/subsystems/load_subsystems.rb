##
## TODO: figure out a better way to load the necessary code
##

# puts '#'*20
# puts 'loading subsystems'
# puts '#'*20

def self.require_path(relative_path)
  absolute_path = File.expand_path(relative_path, File.dirname(__FILE__))
  Dir["#{absolute_path}/*.rb"].each do |file|
    # puts "  === requiring #{file} === "
    require file
  end
end

require_path('./entity_ss')
require_path('./entity_ss/models')
require_path('./entity_ss/routines')

require_path('./role_ss')
require_path('./role_ss/models')
require_path('./role_ss/routines')

require_path('./course_ss')
require_path('./course_ss/models')
require_path('./course_ss/routines')
