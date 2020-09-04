require 'bundler/gem_tasks'
require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new(:spec)

require 'rubocop/rake_task'
desc 'Run RuboCop on the lib directory'
RuboCop::RakeTask.new(:rubocop) do |task|
  task.options = ['--no-color', '--out=rubocop-results.xml', '--format', 'simple']
  task.formatters = ['RuboCop::Formatter::CheckstyleFormatter']
  task.requires = ['rubocop/formatter/checkstyle_formatter']
  # don't abort rake on failure
  task.fail_on_error = false
end

# Load in the rake tasks from the base openstudio-extension gem
require 'openstudio/extension/rake_task'
require 'openstudio/alfalfa'
os_extension = OpenStudio::Extension::RakeTask.new
os_extension.set_extension_class(OpenStudio::Alfalfa::Alfalfa)

task default: :spec
