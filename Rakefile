#!/usr/bin/env rake

# Install tasks to build and release the plugin
require 'bundler/setup'
Bundler::GemHelper.install_tasks

# Install test tasks
require 'rspec/core/rake_task'
desc "Run RSpec"
RSpec::Core::RakeTask.new

# Run tests by default
task :default => :spec
