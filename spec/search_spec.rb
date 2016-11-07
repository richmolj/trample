require 'spec_helper'

describe Trample::Search do

  let(:klass) do
    Class.new(described_class)
  end

  let(:instance) { klass.new }

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

  describe '#page' do
    subject { instance.page(2) }

    it 'sets current page' do
      subject
      expect(instance.metadata.current_page).to eq(2)
    end

    it { is_expected.to be_a(klass) }
  end

  describe '#per' do
    subject { instance.per(50) }

    it 'sets per_page' do
      subject
      expect(instance.metadata.per_page).to eq(50)
    end

    it { is_expected.to be_a(klass) }
  end
end
