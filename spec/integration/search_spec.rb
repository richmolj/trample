require 'spec_helper'

RSpec.describe "searching", elasticsearch: true do

  let(:klass) do
    Class.new(Trample::Search) do
      condition :name
      condition :tags
      condition :age
    end
  end

  before do
    Searchkick.client.indices.delete index: '_all'
    Person.create!(name: 'Homer', tags: ['funny', 'stupid', 'bald'], age: 38)
    Person.create!(name: 'Lisa', tags: ['funny', 'smart'], age: 8)
    Person.create!(name: 'Marge', tags: ['motherly'], age: 34)
    Person.create!(name: 'Bart', tags: ['funny', 'stupid'], age: 10)
    Person.reindex
    Person.searchkick_index.refresh

    klass.model(Person)
  end

  it "records time the search took" do
    results = double(response: {'took' => 2}).as_null_object
    allow(Person).to receive(:search).and_return(results)
    search = klass.new
    search.query!
    expect(search.metadata.took).to eq(2)
  end

  it "records total entries" do
    results = double(total_count: 12).as_null_object
    allow(Person).to receive(:search).and_return(results)
    search = klass.new
    search.query!
    expect(search.metadata.total).to eq(12)
  end

  it "can query correctly when manually assigning" do
    search = klass.new
    search.condition(:name).eq('Homer')
    search.query!

    expect(search.results.length).to eq(1)
  end

  it "queries basic conditions correctly via constructor" do
    search = klass.new(conditions: {name: "Homer"})
    search.query!

    expect(search.results.length).to eq(1)
  end

  it "queries arrays OR'd via constructor correctly" do
    search = klass.new(conditions: {tags: {values: ['funny', 'stupid'], and: false}})
    search.query!

    expect(search.results.map(&:name)).to match_array(['Homer', 'Lisa', 'Bart'])
  end

  it "queries arrays OR'd via direct assignment correctly" do
    search = klass.new
    search.condition(:tags).or(%w(funny stupid))
    search.query!

    expect(search.results.map(&:name)).to match_array(['Homer', 'Lisa', 'Bart'])
  end

  it "queries arrays AND'd via constructor correctly" do
    search = klass.new(conditions: {tags: {values: ['funny', 'stupid'], and: true}})
    search.query!

    expect(search.results.map(&:name)).to match_array(['Homer', 'Bart'])
  end

  it "queries arrays AND'd via direct assignment correctly" do
    search = klass.new
    search.condition(:tags).and(%w(funny stupid))
    search.query!

    expect(search.results.map(&:name)).to match_array(['Homer', 'Bart'])
  end

  it "queries NOT via constructor correctly" do
    search = klass.new(conditions: {name: {values: 'Bart', not: true}})
    search.query!

    expect(search.results.map(&:name)).to match_array(['Homer', 'Marge', 'Lisa'])
  end

  it "queries NOT via direct assignment correctly" do
    search = klass.new
    search.condition(:name).not('Bart')
    search.query!

    expect(search.results.map(&:name)).to match_array(['Homer', 'Marge', 'Lisa'])
  end

  it "queries NOT IN via constructor correctly" do
    search = klass.new(conditions: {name: {values: ['Bart', 'Lisa'], not: true}})
    search.query!

    expect(search.results.map(&:name)).to match_array(['Homer', 'Marge'])
  end

  it "queries NOT IN via direct assignment correctly" do
    search = klass.new
    search.condition(:name).not(['Bart', 'Lisa'])
    search.query!

    expect(search.results.map(&:name)).to match_array(['Homer', 'Marge'])
  end

  it "queries gte via constructor correctly" do
    search = klass.new(conditions: {age: {from: 34}})
    search.query!

    expect(search.results.map(&:name)).to match_array(['Homer', 'Marge'])
  end

  it "queries gte via direct assignment correctly" do
    search = klass.new
    search.condition(:age).gte(34)
    search.query!

    expect(search.results.map(&:name)).to match_array(['Homer', 'Marge'])
  end

  it "queries lte via constructor correctly" do
    search = klass.new(conditions: {age: {to: 34}})
    search.query!

    expect(search.results.map(&:name)).to match_array(['Bart', 'Lisa', 'Marge'])
  end

  it "queries lte via direct assignment correctly" do
    search = klass.new
    search.condition(:age).lte(34)
    search.query!

    expect(search.results.map(&:name)).to match_array(['Bart', 'Lisa', 'Marge'])
  end

  it "queries WITHIN via constructor correctly" do
    search = klass.new
    search.condition(:age).within(10..34)
    search.query!

    expect(search.results.map(&:name)).to match_array(['Bart', 'Marge'])
  end

  it "queries WITHIN via direct assignment correctly" do
    search = klass.new(conditions: {age: {from: 10, to: 34}})
    search.query!

    expect(search.results.map(&:name)).to match_array(['Bart', 'Marge'])
  end

end
