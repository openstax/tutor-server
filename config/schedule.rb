every 1.minute do
  runner "OpenStax::Accounts::SyncAccounts.call"
  runner "OpenStax::Accounts::SyncGroups.call"
end
