require 'rails_helper'

RSpec.describe Legal, type: :module do

  let(:district)     { FactoryBot.create :school_district_district }
  let(:district_gid) { Legal::Utils.gid(district) }
  let(:school)       { FactoryBot.create :school_district_school, district: district }
  let(:school_gid)   { Legal::Utils.gid(school) }
  let(:course)       { FactoryBot.create :course_profile_course, school: school }
  let(:course_gid)   { Legal::Utils.gid(course) }

  before do
    allow(Legal::Utils).to receive(:available_contract_names) do
      %w(contract_a contract_b contract_c masked_1 masked_2)
    end
  end

  it 'reports parameters through the PORO' do
    tc = Legal::CreateTargetedContract[
      contract_name: 'contract_a',
      target_gid: course_gid,
      target_name: 'A Name',
      masked_contract_names: ['masked_1'],
      is_proxy_signed: true
    ]

    expect(tc.contract_name).to eq 'contract_a'
    expect(tc.target_gid).to eq course_gid
    expect(tc.target_name).to eq 'A Name'
    expect(tc.masked_contract_names).to eq ['masked_1']
    expect(tc.is_proxy_signed).to be_truthy
    expect(tc.is_end_user_visible).to be_truthy
  end

  it 'can create and retrieve a direct targeted contract' do
    Legal::CreateTargetedContract[
      contract_name: 'contract_a',
      target_gid: course_gid,
      target_name: 'A Name'
    ]

    matching_contracts = Legal::GetTargetedContracts[applicable_to: course]

    expect(matching_contracts.size).to eq 1
    expect(matching_contracts.first.contract_name).to eq 'contract_a'
  end

  it 'can create and retrieve a targeted contract from a parent' do
    Legal::CreateTargetedContract[
      contract_name: 'contract_a',
      target_gid: school_gid,
      target_name: 'A Name'
    ]

    matching_contracts = Legal::GetTargetedContracts[applicable_to: course]

    expect(matching_contracts.size).to eq 1
    expect(matching_contracts.first.contract_name).to eq 'contract_a'
  end

  it 'can create and retrieve a targeted contract from an ancestor' do
    Legal::CreateTargetedContract[
      contract_name: 'contract_a',
      target_gid: district_gid,
      target_name: 'A Name'
    ]

    matching_contracts = Legal::GetTargetedContracts[applicable_to: course]

    expect(matching_contracts.size).to eq 1
    expect(matching_contracts.first.contract_name).to eq 'contract_a'
  end

  it 'can get a targeted contract from an ancestor and then cut the link' do
    Legal::CreateTargetedContract[
      contract_name: 'contract_a',
      target_gid: district_gid,
      target_name: 'A Name'
    ]

    school.update_attribute :district, nil

    matching_contracts = Legal::GetTargetedContracts[applicable_to: course]
    expect(matching_contracts.size).to eq 0

    matching_contracts = Legal::GetTargetedContracts[applicable_to: district]
    expect(matching_contracts.size).to eq 1
  end

  context 'in a three-level ancestry' do
    before do
      Legal::CreateTargetedContract[
        contract_name: 'contract_a',
        target_gid: district_gid,
        target_name: 'A Name'
      ]
    end

    # If this functionality is necessary, we can implement it by adding a boolean to the course
    it 'cannot forget about the lowest child' do
      Legal::ForgetAbout[item: course]

      expect(Legal::GetTargetedContracts[applicable_to: course].size).to eq 1
      expect(Legal::GetTargetedContracts[applicable_to: school].size).to eq 1
      expect(Legal::GetTargetedContracts[applicable_to: district].size).to eq 1
    end

    # If this functionality is necessary, we can implement it by adding a boolean to the school
    it 'cannot forget about the middle child' do
      Legal::ForgetAbout[item: school]

      expect(Legal::GetTargetedContracts[applicable_to: course].size).to eq 1
      expect(Legal::GetTargetedContracts[applicable_to: school].size).to eq 1
      expect(Legal::GetTargetedContracts[applicable_to: district].size).to eq 1
    end

    it 'can forget about the top parent' do
      Legal::ForgetAbout[item: district]

      expect(Legal::GetTargetedContracts[applicable_to: course].size).to eq 0
      expect(Legal::GetTargetedContracts[applicable_to: school].size).to eq 0
      expect(Legal::GetTargetedContracts[applicable_to: district].size).to eq 0
    end
  end

  it 'can destroy targeted contracts' do
    tc = Legal::CreateTargetedContract[
      contract_name: 'contract_a',
      target_gid: district_gid,
      target_name: 'A Name'
    ]

    expect(Legal::GetTargetedContracts[applicable_to: course].size).to eq 1
    expect(Legal::GetTargetedContracts[applicable_to: school].size).to eq 1
    expect(Legal::GetTargetedContracts[applicable_to: district].size).to eq 1

    Legal::DestroyTargetedContract[id: tc.id]

    expect(Legal::GetTargetedContracts[applicable_to: course].size).to eq 0
    expect(Legal::GetTargetedContracts[applicable_to: school].size).to eq 0
    expect(Legal::GetTargetedContracts[applicable_to: district].size).to eq 0
  end

  it 'verifies contract names against FinePrint' do
    result = Legal::CreateTargetedContract.call(
      contract_name: 'contract_a',
      target_gid: course_gid,
      target_name: 'A Name',
      masked_contract_names: ['blah']
    )

    expect(result.errors.first.code).to eq :contract_does_not_exist
  end

  it 'can get contract names by proxy and non-proxy and with masks' do
    school_2 = FactoryBot.create :school_district_school
    school_2_gid = Legal::Utils.gid(school_2)
    course_2 = FactoryBot.create :course_profile_course, school: school_2

    Legal::CreateTargetedContract[
      contract_name: 'contract_a',
      target_gid: school_gid,
      target_name: 'A Name',
      is_proxy_signed: true
    ]
    Legal::CreateTargetedContract[
      contract_name: 'contract_b',
      target_gid: course_gid,
      target_name: 'B Name',
      masked_contract_names: ['masked_1']
    ]
    Legal::CreateTargetedContract[
      contract_name: 'contract_c',
      target_gid: school_2_gid,
      target_name: 'C Name'
    ]

    contract_names = Legal::GetContractNames.call(
      applicable_to: [course, course_2],
      contract_names_signed_by_everyone: ['masked_1', 'masked_2']
    ).outputs

    expect(contract_names.proxy_signed.size).to eq 1
    expect(contract_names.proxy_signed).to include(a_collection_including(
      'contract_a'
    ))

    expect(contract_names.non_proxy_signed.size).to eq 3
    expect(Set.new(contract_names.non_proxy_signed)).to eq Set.new(
      ['contract_b', 'contract_c', 'masked_2']
    )
  end

end
