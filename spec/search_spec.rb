require 'spec_helper'

describe Trample::Search do

  let(:klass) do
    Class.new(described_class)
  end

  describe "inheritance" do
    let(:subklass) { Class.new(klass) }

    before do
      klass.condition :name
    end

    it "should contain parent conditions in the subclass" do
      expect(subklass._conditions.keys.length).to eq(1)
    end

    it "should not affect the parent when a subclass condition is edited" do
      expect do
        subklass._conditions[:name].name = :changed
      end.to_not change { klass._conditions[:name] }
    end
  end

  describe ".condition" do
    it "should add to the conditions array" do
      expect do
        klass.condition :name
      end.to change { klass._conditions.keys.length }.by(1)
    end

    it "should assign a condition name" do
      klass.condition :name
      expect(klass._conditions[:name].name).to eq(:name)
    end
  end

end
