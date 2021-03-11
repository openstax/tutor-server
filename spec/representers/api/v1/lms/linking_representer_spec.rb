require 'rails_helper'

RSpec.describe Api::V1::Lms::LinkingRepresenter, type: :representer do
  let(:app)               { FactoryBot.create :lms_app }
  let(:environment)       { FactoryBot.create :environment }
  let(:stubbed_app)       { Lms::Models::StubbedApp.new environment }

  let(:configuration_url) { UrlGenerator.new.lms_configuration_url(format: :xml) }
  let(:launch_url)        { UrlGenerator.new.lms_launch_url }

  let(:xml)               { "<something>text</something>" }
  let(:options)           { { user_options: { xml: xml } } }

  it 'displays the info needed to link to the LMS' do
    expect(described_class.new(app).to_hash(options).symbolize_keys).to eq(
      key: app.key,
      secret: app.secret,
      configuration_url: configuration_url,
      launch_url: launch_url,
      xml: xml
    )
  end

  it 'displays stubbed info when given a StubbedApp' do
    stub = "Copied from #{environment.name}"

    expect(described_class.new(stubbed_app).to_hash(options).symbolize_keys).to eq(
      key: stub,
      secret: stub,
      configuration_url: configuration_url,
      launch_url: launch_url,
      xml: xml
    )
  end
end
