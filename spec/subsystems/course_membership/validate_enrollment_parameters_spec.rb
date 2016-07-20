require 'rails_helper'

describe CourseMembership::ValidateEnrollmentParameters, type: :routine do

  let(:course)     { Entity::Course.create!           }
  let(:period)     { CreatePeriod[course: course]     }
  let(:book)       { FactoryGirl.create :content_book }
  let!(:ecosystem) {
    ecosystem = Content::Ecosystem.new(strategy: book.ecosystem.wrap)
    AddEcosystemToCourse[course: course, ecosystem: ecosystem]
    ecosystem
  }

  let(:user)       {
    profile = FactoryGirl.create :user_profile
    strategy = ::User::Strategies::Direct::User.new(profile)
    ::User::User.new(strategy: strategy)
  }

  it "returns false when requesting with random uuid / enrollment code" do
    expect( described_class[book_uuid:'unknown', enrollment_code: 'yo momma'] ).to eq(false)
  end

  it "returns false if book_uuid is valid but enrollment_code is not" do
    expect( described_class[book_uuid: book.uuid, enrollment_code: 'yo momma'] ).to eq(false)
  end

  it "returns false if book_uuid is invalid even if enrollment_code is" do
    expect( described_class[book_uuid: 'hackme', enrollment_code: period.enrollment_code] ).to(
      eq(false)
    )
  end

  it "returns true if both book_uuid and enrollment_code is valid" do
    expect( described_class[book_uuid: book.uuid, enrollment_code: period.enrollment_code] ).to(
      eq(true)
    )
  end

end
