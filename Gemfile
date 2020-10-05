source 'https://rubygems.org'

# Specify your gem's dependencies in u-observers.gemspec
gemspec

activerecord_version = ENV.fetch('ACTIVERECORD_VERSION', '6.1')

activerecord = case activerecord_version
              when '3.2' then '3.2.22'
              when '4.0' then '4.0.13'
              when '4.1' then '4.1.16'
              when '4.2' then '4.2.11'
              when '5.0' then '5.0.7'
              when '5.1' then '5.1.7'
              when '5.2' then '5.2.3'
              when '6.0' then '6.0.3'
              end

simplecov_version =
  case RUBY_VERSION
  when /\A2.[23]/ then '~> 0.17.1'
  when /\A2.4/ then '~> 0.18.5'
  else '~> 0.19'
  end

group :test do
  gem 'minitest', activerecord_version < '4.1' ? '~> 4.2' : '~> 5.0'
  gem 'simplecov', simplecov_version, require: false

  if activerecord
    sqlite3 =
      case activerecord
      when /\A6\.0/, nil then '~> 1.4.0'
      else '~> 1.3.0'
      end

    gem 'sqlite3', sqlite3
    gem 'activerecord', activerecord, require: 'active_record'
  end
end
