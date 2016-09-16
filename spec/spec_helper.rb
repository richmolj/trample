$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'trample'
require 'database_cleaner'
require 'active_record'
require 'pry'
require 'pry-byebug'

ENV['HTTP_PROXY'] = nil
ENV['http_proxy'] = nil

RSpec.configure do |config|
  config.before(:suite) do
    DatabaseCleaner.strategy = :transaction
    DatabaseCleaner.clean_with(:truncation)
  end

  config.around(:each) do |example|
    DatabaseCleaner.cleaning do
      example.run
    end
  end

end

ActiveRecord::Migration.verbose = false
ActiveRecord::Base.establish_connection(:adapter => "sqlite3", :database => ":memory:")
ActiveRecord::Base.raise_in_transactional_callbacks = true

ActiveRecord::Schema.define(:version => 1) do
  create_table :people do |t|
    t.string :name
    t.text :tags
    t.integer :age
    t.integer :company_id
  end

  create_table :animals do |t|
    t.integer :person_id
    t.string :name
  end

  create_table :companies do |t|
    t.string :name
  end
end

class Person < ActiveRecord::Base
  searchkick text_start: [:name, :tags],
    text_middle: [:name], autocomplete: [:name]

  serialize :tags

  has_many :animals
  belongs_to :company

  def search_data
    attrs = self.attributes.clone

    if company.present?
      attrs.update(company_id: company.id, company_name: company.name)
    end

    attrs
  end
end

class Animal < ActiveRecord::Base
  searchkick text_start: [:name]

  belongs_to :person
end

class Company < ActiveRecord::Base
  has_many :people
end

Searchkick.disable_callbacks

# Avoid hitting same port as probably used for development.
host = ENV['ELASTICSEARCH_HOST'] || 'localhost'
host = ENV['ELASTICSEARCH_PORT'] || 9250
config = {
  hosts: [{host: host, port: port}],
  log: false
}

Searchkick.client = Elasticsearch::Client.new(config)
