namespace :lint do
  SRC_PATHS = 'app lib spec'.freeze
  HEAD = ENV['TRAVIS_BRANCH'] || 'head'

  def exec_git(cmd)
    return if HEAD == 'master'

    sh "git #{cmd} | xargs rubocop" do |ok|
      abort 'style errors!' unless ok
    end
  end

  desc 'run robocop on files that differ from master'
  task :branch do
    exec_git "diff-tree -r --no-commit-id --porcelain --name-only #{HEAD} origin/master #{SRC_PATHS}"
  end

  task :uncommited do
    exec_git "status --short --porcelain #{SRC_PATHS} | awk '{ print $2 }'"
  end
end
