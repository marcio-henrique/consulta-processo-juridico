namespace :import do
  desc "Import lawsuits and movements from a CSV (default: LAWSUITS_CSV_PATH or ../data/lawsuits_movements.csv)"
  task :lawsuits, [ :path ] => :environment do |_task, args|
    path = args[:path].presence || Imports::LawsuitsCsv.default_path
    puts Imports::LawsuitsCsv.call(path)
  rescue Imports::FatalError => e
    abort "Import failed: #{e.message}"
  end
end
