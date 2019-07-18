require 'bundler/inline'

gemfile do
  source 'https://rubygems.org'
  gem 'json'
  gem 'pry'
  gem 'kramdown'
end

require 'kramdown'
require 'json'
require 'pry'

def main
  manifest_file= File.read('manifest.json')
  manifest = JSON.parse(manifest_file)

  manifest.each do |manifest_entry|
    if !manifest_entry["src"].nil? && !manifest_entry["content"].nil?
      begin
        article = File.read(manifest_entry["src"])
        File.write(manifest_entry["content"], Kramdown::Document.new(article).to_html)
        puts "Writing #{manifest_entry["src"]} to #{manifest_entry["content"]}"

      rescue Errno::ENOENT
        puts "Skipping #{manifest_entry["src"]}"
      end
    end
  end
end

main
