require 'gitlab'
client = Gitlab.client(
  endpoint: 'http://gitlab-ee-11-11-8.gldev//api/v4',
  private_token: 'ojQcRhNgXxcXhJuEx6gF'
)

require 'faker'
def gen_groups
  [
    Faker::TvShows::GameOfThrones.house,
    Faker::Food.dish,
    Faker::TvShows::ParksAndRec.city,
    Faker::TvShows::SiliconValley.company
  ].sample.gsub(/[^0-9A-Za-z]/, '')
end

def gen_projects
  [
    Faker::App.name,
    Faker::Food.spice,
    Faker::TvShows::SiliconValley.app,
    Faker::University.name
  ].sample.downcase.gsub(/[^0-9A-Za-z]/, '')
end

def gen_people
  [
    Faker::Movies::BackToTheFuture.character,
    Faker::TvShows::HowIMetYourMother.character,
    Faker::TvShows::GameOfThrones.character,
    Faker::TvShows::ParksAndRec.character
  ].sample
end

def gen_description
  [
    Faker::Hacker.say_something_smart,
    Faker::Company.bs
  ].sample
end


user_count = 55
group_count = 15042
people = Array.new(user_count) { gen_people }.uniq
groups = Array.new(group_count) { gen_groups }.uniq

users = people.map do |user|
    username = user.downcase.gsub(/[^0-9A-Za-z]/, '')
    email = "#{username}@blah.gldev"
    password = 'blahblahblah'
    puts "User -- Name: #{user}, UserName: #{username}, Email: #{email}"
    client.create_user(email, password, username, name: user)
end

groups = groups.map do |group|
    path = group.downcase.gsub(/[^0-9A-Za-z]/, '')
    puts "Group -- #{group}/#{path}"
    begin
        client.create_group(group, path)
    rescue Gitlab::Error::BadRequest
        # whatever
    end
end

group_access = [10, 20, 30, 40, 50]
groups.each do |group|
  users.sample(rand(1..users.count)).each do |user|
    begin
      puts "Group Add: #{group.name}: #{user.name}"
      client.add_group_member(group.id, user.id, group_access.sample)
    rescue StandardError
      next
    end
  end
end

project_range = 2..10
groups.each do |group|
  project_names = Array.new(rand(project_range)) { gen_projects }
  project_names.uniq.each do |project|
    puts "Project: #{project}"
    options = {
      description: gen_description,
      default_branch: 'master',
      issues_enabled: 1,
      wiki_enabled: 1,
      merge_requests_enabled: 1,
      namespace_id: group.id
    }
    client.create_project(project, options)
  end
end

client.projects.auto_paginate .each do |project|
    group = client.group(project.to_h.dig('namespace', 'id'))
    members = client.group_members(group.id).auto_paginate
    rand(5..40).times do
      options = {
        description: Faker::Hacker.say_something_smart,
        assignee_id: members.sample.id
      }
      client.create_issue(project.id, Faker::Company.catch_phrase, options)
      puts 'Issue Created'
    end
  end
