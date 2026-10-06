# frozen_string_literal: true

require "bundler/gem_tasks"
require "minitest/test_task"
require "rubocop/rake_task"
require "fileutils"
require "rbconfig"
require "yard"

Minitest::TestTask.create do |t|
  t.test_globs = ["test/**/*_test.rb"]
end

RuboCop::RakeTask.new

YARD::Rake::YardocTask.new do |task|
  task.before = -> { FileUtils.rm_rf(File.join(__dir__, "doc")) }
end

desc "Generate Markdown API documentation and the LLM index"
task docs: :yard do
  sh RbConfig.ruby, File.join(__dir__, "bin/generate_llm.rb")
end

begin
  require "branchproof/rake_task"

  Branchproof::RakeTask.new(:branchproof) do |t|
    t.sources = ["lib/**/*.rb"]
    t.tests = ["test/**/*_test.rb"]
    t.project = "ruby"
    t.framework = "minitest"
    t.minimum = ["mcdc=90"]
  end
rescue LoadError
  raise if Gem::Version.new(RUBY_VERSION) >= Gem::Version.new("4.0")

  desc "Branchproof needs Ruby 4.0+"
  task(:branchproof) { warn "branchproof not installed on this Ruby" }
end

desc "Run quality_gate fast, verify and audit"
task :quality do
  %w[fast verify audit].each do |gate|
    sh "bundle exec quality_gate #{gate}"
  end
end

task default: %i[test rubocop]
