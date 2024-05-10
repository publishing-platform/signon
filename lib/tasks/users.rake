namespace :users do
  desc "Create a new user (specify name and email in environment)"
  task create: :environment do
    raise "Requires name and email in environment" unless ENV["name"] && ENV["email"]

    user = User.invite!(name: ENV["name"], email: ENV["email"], role: ENV["role"] || "normal")

    if user.errors.empty?
      puts "User created: user.name <#{user.name}>"
      puts "              user.email <#{user.email}>"
      puts "              invitation token: <#{user.raw_invitation_token}>"
    else
      puts "Error creating user:"
      user.errors.full_messages.each { |message| puts "<#{message}>" }
    end
  end
end
