# frozen_string_literal: true

# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: 'Star Wars' }, { name: 'Lord of the Rings' }])
#   Character.create(name: 'Luke', movie: movies.first)

default_groups = %i[administrators users]
groups = {}
default_groups.each do |group_name|
  groups[group_name.to_sym] = Group.find_or_create_by!(name: group_name)
end
Group.where(name: 'administrators').update({ admin: true })

email = Email.find_by(address: ENV['SEED_EMAIL'].presence || 'admin@example.com')
user = if email
         email.user
       else
         User.new(email: ENV['SEED_EMAIL'].presence || 'admin@example.com')
       end
if user.persisted?
  puts "User with email '#{user.email}' already exists, not seeding."
  exit
end

user.username = ENV['SEED_USERNAME'].presence || 'admin'
user.password = ENV['SEED_PASSWORD'].presence || 'password123'
puts "Creating user '#{user.username}' with password: '#{user.password}'"
user.password_confirmation = ENV['SEED_PASSWORD'].presence || 'password123'
user.groups << groups[:administrators]
user.save!
