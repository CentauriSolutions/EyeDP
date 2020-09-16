# frozen_string_literal: true

namespace :eyedp do
  desc 'TODO'
  task :create_admin_user, [:username] => [:environment] do |_task, args|
    username = args[:username] || 'admin'
    password = SecureRandom.hex
    puts "Creating user '#{username}' with password: '#{password}'"
    user = User.create(username: username, email: 'admin@localhost', password: password)
    user.groups << Group.where(name: 'administrators').find
  end
end
