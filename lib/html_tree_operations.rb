module HtmlTreeOperations
  # Recursively removes a node and its empty parents
  def recursive_compact(node, root)
    return if node == root

    parent = node.parent
    node.remove

    recursive_compact(parent, root) if parent && parent.content.blank?
  end

  # Recursively removes all siblings before a node and its parents
  def remove_before(node, root)
    return if node == root

    parent = node.parent
    siblings = parent.children
    index = siblings.index(node)
    parent.children = siblings.slice(index..-1)
    remove_before(parent, root)
  end

  # Recursively removes all siblings after a node and its parents
  def remove_after(node, root)
    return if node == root

    parent = node.parent
    siblings = parent.children
    index = siblings.index(node)
    parent.children = siblings.slice(0..index)
    remove_after(parent, root)
  end
end
