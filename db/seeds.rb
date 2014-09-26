# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)

# FinePrint Contracts
FinePrint::Contract.create do |contract|
  contract.name    = 'general_terms_of_use'
  contract.version = 1
  contract.title   = 'Terms of Use'
  contract.content = 'Placeholder for general terms of use, required for new installations to function'
end

FinePrint::Contract.create do |contract|
  contract.name    = 'privacy_policy'
  contract.version = 1
  contract.title   = 'Privacy Policy'
  contract.content = 'Placeholder for privacy policy, required for new installations to function'
end
