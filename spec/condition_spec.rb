require 'spec_helper'

RSpec.describe Trample::Condition do

  let(:attrs)    { {} }
  let(:instance) { described_class.new(attrs) }

  class Myklass
    include Virtus.model
    def load(values)
      []
    end
  end

  describe "#lookup_autocomplete" do
    context "with custom default lookup klass" do
      before do
        attrs[:lookup] = { key: :test_id, label: :test_label, klass: :Myklass }
      end
      it "should load autocomplete labels using custom klass" do
        results = [{key: 2, text: "two"}, {key: 4, text: "four"}]
        expect(Myklass).to receive(:new).and_return(double(load: results))
        instance.values = [{key: 2}, {key: 4}]
        instance.lookup_autocomplete

        expect(instance.values).to eql(results)
      end
    end

    context "with default lookup klass" do
      before do
        attrs[:lookup] = { key: :test_id, label: :test_label }
      end
      context "when all values has missing text key" do
        context "when all labels are missing" do
          it "should load autocomplete labels" do
            results = [{key: 2, text: "two"}, {key: 4, text: "four"}]
            expect(Trample::TextLookup).to receive(:new).and_return(double(load: results))
            instance.values = [{key: 2}, {key: 4}]
            instance.lookup_autocomplete

            expect(instance.values).to eql(results)
          end
        end

        context "when any labels are missing" do
          it "should load autocomplete labels" do
            results = [{key: 2, text: "two"}, {key: 4, text: "four"}]
            expect(Trample::TextLookup).to receive(:new).and_return(double(load: results))
            instance.values = [{key: 2, text: "two"}, {key: 4}]
            instance.lookup_autocomplete

            expect(instance.values).to eql(results)
          end
        end

        context "when all labels are present" do
          it "should not load autocomplete labels" do
            expect(Trample::TextLookup).not_to receive(:new)
            instance.values = [{key: 2, text: "two"}, {key: 4, text: "four"}]
            instance.lookup_autocomplete
          end
        end

        context "when condition is not autocomplete type" do
          it "should not load autocomplete labels" do
            expect(Trample::TextLookup).not_to receive(:new)
            instance.values = ['test']
            instance.lookup_autocomplete
          end
        end

        context "when condition value is blank" do
          it "should not load autocomplete labels" do
            expect(Trample::TextLookup).not_to receive(:new)
            instance.lookup_autocomplete
          end
        end
      end
    end
  end

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
