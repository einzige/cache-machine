# encoding: utf-8

ENV['BUNDLE_GEMFILE'] = 'Gemfile'

gem_root = File.expand_path(File.dirname(__FILE__))

require 'rubygems'
require 'bundler'
require 'rake'
require 'jeweler'
require 'rake'
require 'rake/testtask'
require 'rspec'
require 'rspec/core/rake_task'

begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts "Run `bundle install` to install missing gems"
  exit e.status_code
end

Jeweler::Tasks.new do |gem|
  # gem is a Gem::Specification... see http://docs.rubygems.org/read/chapter/20 for more options
  gem.name = "cache-machine"
  gem.homepage = "http://github.com/partyearth/cache-machine"
  gem.license = "MIT"
  gem.summary = %Q{TODO: one-line summary of our gem}
  gem.description = %Q{TODO: longer description of our gem}
  gem.email = "kgoslar@partyearth.ru"
  gem.authors = ["Kevin Goslar"]
  # dependencies defined in Gemfile
end
Jeweler::RubygemsDotOrgTasks.new

task :default => :spec

desc "Run the test suite"
task :spec => ['spec:setup', 'spec:lib', 'spec:cleanup']

namespace :spec do
  desc "Setup the test environment"
  task :setup do
    system "cd #{gem_root} && bundle install && mkdir db"
  end

  desc "Cleanup the test environment"
  task :cleanup do
    FileUtils.rm_rf "#{gem_root}/db"
  end

  desc "Test the Cache Machine lib"
  RSpec::Core::RakeTask.new(:lib) do |task|
    task.pattern = gem_root + '/spec/lib/**/*_spec.rb'
  end
end

require 'rdoc/task'
Rake::RDocTask.new do |rdoc|
  version = File.exist?('VERSION') ? File.read('VERSION') : ""

  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "cache-machine #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end
