require 'rails_helper'

RSpec.describe HtmlTreeOperations, type: :lib do
  class HtmlTreeOperationsUser
    include HtmlTreeOperations
  end

  subject(:html_tree) { HtmlTreeOperationsUser.new }

  let(:top) { OpenStruct.new(parent: nil, remove: nil, children: [], content: 'stop') }
  let(:parent) { OpenStruct.new(parent: top, remove: nil, children: [], content: '') }
  let(:left) { OpenStruct.new(parent: parent, remove: nil, content: 'left') }
  let(:right) { OpenStruct.new(parent: parent, remove: nil, content: 'right') }
  let(:node) { OpenStruct.new(parent: parent, remove: nil, content: 'node') }

  context '#recursive_compact' do
    it 'stops at the indicated stop_node' do
      expect(html_tree.recursive_compact(node, node)).to be_nil
    end

    it 'removes the passed in node' do
      allow(node).to receive(:remove)
      html_tree.recursive_compact(node, top)
      expect(node).to have_received(:remove)
    end

    it 'removes empty parents recursively' do
      allow(parent).to receive(:remove)
      html_tree.recursive_compact(node, top)
      expect(parent).to have_received(:remove)
    end
  end

  context '#remove_before' do
    it 'stops at the indicated stop_node' do
      expect(html_tree.remove_before(node, node)).to be_nil
    end

    it 'removes siblings before the node recursively' do
      top.children = [parent]
      parent.children = [left, node, right]

      html_tree.remove_before(node, top)

      expect(parent.children).to eq([node, right])
    end
  end

  context '#remove_after' do
    it 'stops at the indicated stop_node' do
      expect(html_tree.remove_after(node, node)).to be_nil
    end

    it 'removes siblings after the node recursively' do
      top.children = [parent]
      parent.children = [left, node, right]

      html_tree.remove_after(node, top)

      expect(parent.children).to eq([left, node])
    end
  end
end
