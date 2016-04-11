require 'spec_helper'

RSpec.describe Trample::Condition do

  let(:attrs)    { {} }
  let(:instance) { described_class.new(attrs) }

  describe "#as_json" do
    context "when single-value" do
      before do
        attrs[:single] = true
        instance.values = ['foo']
      end

      it "should output that value directly" do
        expect(instance.as_json).to eq('foo')
      end
    end

    context "when multi-value" do
      before do
        instance.values = ['foo', 'bar']
        instance.and = true
      end

      it "should output values/and hash" do
        expect(instance.as_json)
          .to eq(values: ['foo', 'bar'], and: true)
      end
    end

    context "when range" do
      let(:from) { Time.now }
      let(:to)   { Time.now + 60*60*24 }

      before do
        instance.range = true
        instance.from = from
        instance.to_eq = to
      end

      it "should show correct from/to including _eqs" do
        expect(instance.as_json)
          .to eq(from: from, to_eq: to)
      end
    end
  end

end
