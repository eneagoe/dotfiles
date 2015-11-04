gem 'axlsx', github: 'randym/axlsx' if yes? 'Will it export XLSX?'
gem 'bootstrap-sass'
using_authorization = yes? 'Use cancan for authorization?'
gem 'cancan' if using_authorization
using_delayed = yes? 'Will it do background processing?'
gem 'delayed_job_active_record' if using_delayed
gem 'devise'
gem 'exception_notification'
gem 'font-awesome-rails' if yes? 'Use Font-Awesome?'
gem 'simple_form'
using_navigation = yes? 'Use navigation?'
gem 'simple-navigation' if using_navigation
gem 'slim-rails'
gem 'puma', require: false

gem_group :development, :test do
  gem 'capybara'
  gem 'database_cleaner'
  gem 'dotenv-rails'
  gem 'factory_girl'
  gem 'faker'
  gem 'guard'
  gem 'guard-minitest'
  gem 'launchy'
  gem 'minitest-rails'
  gem 'minitest-rails-capybara'
  gem 'rack-mini-profiler', require: false
  gem 'rails-erd', require: false
  gem 'simplecov'
  gem 'terminal-notifier-guard'
end

using_heroku = yes? 'Use Heroku?'
if using_heroku
  gem_group :production do
    gem 'rails_12factor'
    if using_delayed
      gem 'rush'
      gem 'workless'
    end
  end
end

environment <<-NOGENERATORS
config.generators do |g|
  g.test_framework :minitest, fixture: false
  g.helper = false # don't need empty helpers
  g.assets = false # don't need empty js/css files
end
NOGENERATORS

if using_delayed
  environment <<-DELAYEDCONFIG
    config.active_job.queue_adapter = :delayed_job
DELAYEDCONFIG
end

initializer 'rack_profiler.rb', <<-RACK_PROFILER
if Rails.env.development?
  require 'rack-mini-profiler'

  # initialization is skipped so trigger it
  Rack::MiniProfilerRails.initialize!(Rails.application)
end
RACK_PROFILER

initializer 'mail_setup.rb', <<-MAIL_SETUP
ActionMailer::Base.default_url_options[:host] = ENV['SITE_URL']

ActionMailer::Base.smtp_settings = {
  address:         'smtp.sendgrid.net',
  port:            '25',
  authentication:  :plain,
  user_name:       ENV['SENDGRID_USERNAME'],
  password:        ENV['SENDGRID_PASSWORD'],
  domain:          ENV['SENDGRID_DOMAIN']
}

ActionMailer::Base.delivery_method = :smtp if Rails.env.production?
MAIL_SETUP

file '.rubocop.yml', <<-RUBOCOP
AllCops:
  Include:
    - '**/Rakefile'
  Exclude:
    - 'vendor/**/*'
    - 'db/**/*'
    - 'bin/**/*'
    - 'config/**/*'
  RunRailsCops: true

StringLiterals:
  EnforcedStyle: single_quotes

SpaceInsideHashLiteralBraces:
  EnforcedStyle: no_space

DotPosition:
  EnforcedStyle: trailing

ClassAndModuleChildren:
  Enabled: false
RUBOCOP

file 'config/puma.rb', <<-PUMA
workers Integer(ENV['WEB_CONCURRENCY'] || 2)
threads_count = Integer(ENV['MAX_THREADS'] || 5)
threads threads_count, threads_count

preload_app!

# rackup DefaultRackup
port ENV['PORT'] || 3000
environment ENV['RACK_ENV'] || 'development'

on_worker_boot do
  ActiveRecord::Base.establish_connection
end
PUMA

remove_file 'config/database.yml'
file 'config/database.yml', <<DATABASE_YML
default: &default
  adapter: postgresql
  encoding: unicode
  pool: 5

development:
  <<: *default
  database: #{app_name}_development
  username: <%= ENV['DATABASE_USER'] %>
  password: <%= ENV['DATABASE_PASSWORD'] %>

test:
  <<: *default
  database: #{app_name}_test

production:
  <<: *default
  database: #{app_name}_production
  username: <%= ENV['DATABASE_USER'] %>
  password: <%= ENV['DATABASE_PASSWORD'] %>
DATABASE_YML

run 'cp config/database.yml config/database.yml.sample'

file 'Procfile', <<-PROCFILE
web: bundle exec puma -C config/puma.rb
PROCFILE

file '.env.sample', <<-ENV_SAMPLE
APP_NAME=#{app_name}
SUPPORT_SENDER=FILL_ME_IN
SUPPORT_ADDRESS=FILL_ME_IN
DATABASE_USER=FILL_ME_IN
DATABASE_PASSWORD=FILL_ME_IN
SITE_URL=http://localhost:3000
SENDGRID_USERNAME=FILL_ME_IN
SENDGRID_DOMAIN=FILL_ME_IN
SENDGRID_PASSWORD=FILL_ME_IN
PORT=3000
WEB_CONCURRENCY=2
MAX_THREADS=5
ENV_SAMPLE

run 'touch .env'
run 'touch .env.test'

default_ruby = 'ruby-2.2.2'
ruby_version = ask "Which ruby version (default is #{default_ruby})?"
ruby_version = default_ruby if ruby_version.empty?
file '.ruby-version', <<-RUBY_VERSION
#{ruby_version}
RUBY_VERSION

file '.ruby-gemset', <<-RUBY_GEMSET
#{app_name}
RUBY_GEMSET

remove_file '.gitignore'
file '.gitignore', <<-GITIGNORE
/.bundle
/log/*
!/log/.keep
/tmp
.DS_Store
.bundle
.env
.env.test
coverage
erd.pdf
.sass-cache/
notes.md
doc/*
/config/application.yml
GITIGNORE

remove_file 'test/test_helper.rb'
file 'test/test_helper.rb', <<-TEST_HELPER
require 'simplecov'
SimpleCov.start 'rails'
ENV['RAILS_ENV'] ||= 'test'
require File.expand_path('../../config/environment', __FILE__)
require 'rails/test_help'
require 'capybara/rspec/matchers'
require 'minitest/rails'
require 'minitest/rails/capybara'
require 'minitest/pride'
require 'factory_girl'
require 'database_cleaner'

# include factory_girl helpers
class ActiveSupport::TestCase
  include FactoryGirl::Syntax::Methods
  FactoryGirl.find_definitions
end

# make capybara available in all integration tests
class ActionDispatch::IntegrationTest
  include Capybara::DSL
end

DatabaseCleaner.strategy = :transaction
DatabaseCleaner.clean_with(:truncation)

# include devise helpers
class ActionController::TestCase
  include Devise::TestHelpers
  # ensure database cleanup
  def setup
    DatabaseCleaner.start
  end

  def teardown
    DatabaseCleaner.clean
  end
end
TEST_HELPER

file 'test/factories/factories.rb', <<-FACTORIES
FactoryGirl.define do
end
FACTORIES

remove_file 'README.rdoc'
run 'touch README.md'
run 'echo "# TODO" > notes.md'
run 'echo "- clean up application.rb" >> notes.md'
run 'echo "- organize and comment Gemfile" >> notes.md'
run 'echo "- configure Guardfile" >> notes.md'
run 'echo "- cleanup devise initializer" >> notes.md'
run 'echo "- configure exception notification" >> notes.md'
run 'echo "- configure navigation" >> notes.md' if using_navigation
run 'echo "- add some content to README.md" >> notes.md'

after_bundle do
  run 'guard init'

  if using_heroku
    run "heroku apps:create #{app_name}-staging --remote staging --region eu"
    run "heroku apps:create #{app_name}-production --remote production --region eu"
    if using_delayed
      run "heroku config:add APP_NAME=#{app_name}-staging HEROKU_API_KEY=FILL_ME_IN WORKLESS_MIN_WORKERS=0 WORKLESS_MAX_WORKERS=10 -a #{app_name}-staging"
      run "heroku config:add APP_NAME=#{app_name}-staging HEROKU_API_KEY=FILL_ME_IN WORKLESS_MIN_WORKERS=0 WORKLESS_MAX_WORKERS=10 -a #{app_name}-production"
    end
  end

  generate 'simple_form:install --bootstrap'
  generate 'cancan:ability' if using_authorization
  generate 'devise:install'
  generate 'delayed_job:active_record' if using_delayed
  generate 'exception_notification:install'
  generate :navigation_config if using_navigation

  rake 'db:create:all'
  rake 'db:migrate'

  git :init
  git add: '.'
  git commit: %( -m 'Add application skeleton' )

  say 'All done.'
  run 'say "Rails app generated!"'
end

