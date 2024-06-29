require "bundler/inline"

gemfile(true) do
  source "https://rubygems.org"

  gem "activerecord", "7.1.3.4"
  gem "sqlite3", "~> 1.7"
end

require "active_record"
require "minitest/autorun"
require "logger"

ActiveRecord::Base.establish_connection(adapter: "sqlite3", database: ":memory:")
ActiveRecord::Base.logger = Logger.new(STDOUT)

ActiveRecord::Schema.define do
  create_table :users, force: true do |t|
    t.string :name
  end

  create_table :reports, force: true do |t|
    t.integer :user_id
  end
end

class User < ActiveRecord::Base
  has_many :reports
end

class Report < ActiveRecord::Base
  belongs_to :user
end

class ExampleTest < Minitest::Test
  def setup
    3.times do |i|
      user = User.create(name: "user #{i}")
      2.times { user.reports.create }
    end

    @queries = []
    @subscriber = ActiveSupport::Notifications.subscribe('sql.active_record') do |*args|
      event = ActiveSupport::Notifications::Event.new(*args)
      @queries << event
    end
  end

  def teardown
    ActiveSupport::Notifications.unsubscribe(@subscriber)

    Report.delete_all
    User.delete_all
  end

  def test_n_plus_one_problem
    user_names = Report.all.map { |report| report.user.name }

    assert_equal 6, user_names.size
    expected = [
      'SELECT "reports".* FROM "reports"',
      'SELECT "users".* FROM "users" WHERE "users"."id" = ? LIMIT ?',
      'SELECT "users".* FROM "users" WHERE "users"."id" = ? LIMIT ?',
      'SELECT "users".* FROM "users" WHERE "users"."id" = ? LIMIT ?',
      'SELECT "users".* FROM "users" WHERE "users"."id" = ? LIMIT ?',
      'SELECT "users".* FROM "users" WHERE "users"."id" = ? LIMIT ?',
      'SELECT "users".* FROM "users" WHERE "users"."id" = ? LIMIT ?',
    ]
    actual = @queries.map { |q| q.payload[:sql] }
    assert_equal expected, actual
  end

  def test_n_plus_one_solution
    user_names = Report.preload(:user).map { |report| report.user.name }

    assert_equal 6, user_names.size
    expected = [
      'SELECT "reports".* FROM "reports"',
      'SELECT "users".* FROM "users" WHERE "users"."id" IN (?, ?, ?)'
    ]
    actual = @queries.map { |q| q.payload[:sql] }
    assert_equal expected, actual
  end
end
