# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)

# FinePrint Contracts
FinePrint::Contract.create(
  name:    'general_terms_of_use',
  version: 1,
  title:   'Terms of Use',
  content: 'Placeholder for general terms of use, required for new installations to function.'
)

FinePrint::Contract.create(
  name:    'privacy_policy',
  version: 1,
  title:   'Privacy Policy',
  content: 'Placeholder for privacy policy, required for new installations to function.'
)

FinePrint::Contract.create(
  name:    'exercise_editing',
  version: 1,
  title:   'Authorship Terms of Use',
  content: 'Placeholder for authorship terms of use, required for new installations to function.'
)

# TODO: Temp (remove)
Lti::Platform.create!(
  guid: "760f4742-173b-498d-8abf-ef0778591cec",
  profile: FactoryBot.create(:user_profile),
  issuer: "https://canvas.instructure.com",
  client_id: "10000000000001",
  host: "canvas.docker",
  jwks_endpoint: "http://canvas.docker/api/lti/security/jwks",
  authorization_endpoint: "http://canvas.docker/api/lti/authorize_redirect",
  token_endpoint: "http://canvas.docker/login/oauth2/token"
) if Lti::Platform.count == 0
