namespace :feedback do
  desc "Print helpful / not helpful counts per prompt_version and model (no user data)"
  task report: :environment do
    puts Feedback::Report.call
  end
end
