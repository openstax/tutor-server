require 'rails_helper'

RSpec.describe Legal do

  context do

    before {
      allow(Legal::Utils).to receive(:gid) { |input| input }
      allow(Legal::Utils).to receive(:available_contract_names) {
        %w(contract_a contract_b contract_c masked_1 masked_2)
      }
    }

    it 'reports parameters through the PORO' do
      tc = Legal::CreateTargetedContract[contract_name: 'contract_a', target_gid: 'A', target_name: 'A Name',
                                         masked_contract_names: ['masked_1'], is_proxy_signed: true]

      expect(tc.contract_name).to eq 'contract_a'
      expect(tc.target_gid).to eq 'A'
      expect(tc.target_name).to eq 'A Name'
      expect(tc.masked_contract_names).to eq ['masked_1']
      expect(tc.is_proxy_signed).to be_truthy
      expect(tc.is_end_user_visible).to be_truthy
    end

    it 'can create and retrieve a direct targeted contract' do
      Legal::CreateTargetedContract[contract_name: 'contract_a', target_gid: 'A', target_name: 'A Name']

      matching_contracts = Legal::GetTargetedContracts[applicable_to: 'A']

      expect(matching_contracts.size).to eq 1
      expect(matching_contracts.first.contract_name).to eq 'contract_a'
    end

    it 'can create and retrieve a targeted contract from a parent' do
      Legal::CreateTargetedContract[contract_name: 'contract_a', target_gid: 'A', target_name: 'A Name']
      Legal::MakeChildGetParentContracts[child: 'B', parent: 'A']

      matching_contracts = Legal::GetTargetedContracts[applicable_to: 'B']

      expect(matching_contracts.size).to eq 1
      expect(matching_contracts.first.contract_name).to eq 'contract_a'
    end

    it 'can create and retrieve a targeted contract from an ancestor' do
      Legal::CreateTargetedContract[contract_name: 'contract_a', target_gid: 'A', target_name: 'A Name']
      Legal::MakeChildGetParentContracts[child: 'B', parent: 'A']
      Legal::MakeChildGetParentContracts[child: 'C', parent: 'B']

      matching_contracts = Legal::GetTargetedContracts[applicable_to: 'C']

      expect(matching_contracts.size).to eq 1
      expect(matching_contracts.first.contract_name).to eq 'contract_a'
    end

    it 'can get a targeted contract from an ancestor and then cut the link' do
      Legal::CreateTargetedContract[contract_name: 'contract_a', target_gid: 'A', target_name: 'A Name']
      Legal::MakeChildGetParentContracts[child: 'B', parent: 'A']
      Legal::MakeChildGetParentContracts[child: 'C', parent: 'B']
      Legal::MakeChildNotGetParentContracts[child: 'B', parent: 'A']

      matching_contracts = Legal::GetTargetedContracts[applicable_to: 'C']
      expect(matching_contracts.size).to eq 0

      matching_contracts = Legal::GetTargetedContracts[applicable_to: 'A']
      expect(matching_contracts.size).to eq 1
    end

    context 'in a three-level ancestry' do

      before(:each) {
        Legal::CreateTargetedContract[contract_name: 'contract_a', target_gid: 'A', target_name: 'A Name']
        Legal::MakeChildGetParentContracts[child: 'B', parent: 'A']
        Legal::MakeChildGetParentContracts[child: 'C', parent: 'B']
      }

      it 'can forget about the lowest child' do
        Legal::ForgetAbout[item: 'C']

        expect(Legal::GetTargetedContracts[applicable_to: 'C'].size).to eq 0
        expect(Legal::GetTargetedContracts[applicable_to: 'B'].size).to eq 1
        expect(Legal::GetTargetedContracts[applicable_to: 'A'].size).to eq 1
      end

      it 'can forget about the middle child' do
        Legal::ForgetAbout[item: 'B']

        expect(Legal::GetTargetedContracts[applicable_to: 'C'].size).to eq 0
        expect(Legal::GetTargetedContracts[applicable_to: 'B'].size).to eq 0
        expect(Legal::GetTargetedContracts[applicable_to: 'A'].size).to eq 1
      end

      it 'can forget about the top parent' do
        Legal::ForgetAbout[item: 'A']

        expect(Legal::GetTargetedContracts[applicable_to: 'C'].size).to eq 0
        expect(Legal::GetTargetedContracts[applicable_to: 'B'].size).to eq 0
        expect(Legal::GetTargetedContracts[applicable_to: 'A'].size).to eq 0
      end
    end

    it 'can destroy targeted contracts' do
      tc = Legal::CreateTargetedContract[contract_name: 'contract_a', target_gid: 'A', target_name: 'A Name']
      Legal::MakeChildGetParentContracts[child: 'B', parent: 'A']

      expect(Legal::GetTargetedContracts[applicable_to: 'B'].size).to eq 1
      expect(Legal::GetTargetedContracts[applicable_to: 'A'].size).to eq 1

      Legal::DestroyTargetedContract[id: tc.id]

      expect(Legal::GetTargetedContracts[applicable_to: 'B'].size).to eq 0
      expect(Legal::GetTargetedContracts[applicable_to: 'A'].size).to eq 0
    end

    it 'verifies contract names against FinePrint' do
      result = Legal::CreateTargetedContract.call(
                 contract_name: 'contract_a', target_gid: 'A',
                 target_name: 'A Name', masked_contract_names: ['blah']
               )

      expect(result.errors.first.code).to eq :contract_does_not_exist
    end

    it 'can get contract names by proxy and non-proxy and with masks' do
      Legal::CreateTargetedContract[contract_name: 'contract_a', target_gid: 'A', target_name: 'A Name', is_proxy_signed: true]
      Legal::CreateTargetedContract[contract_name: 'contract_b', target_gid: 'B', target_name: 'B Name', masked_contract_names: ['masked_1']]
      Legal::CreateTargetedContract[contract_name: 'contract_c', target_gid: 'C', target_name: 'C Name']
      Legal::MakeChildGetParentContracts[child: 'B', parent: 'A']
      Legal::MakeChildGetParentContracts[child: 'D', parent: 'C']

      contract_names = Legal::GetContractNames.call(
        applicable_to: ['B', 'D'],
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

end
