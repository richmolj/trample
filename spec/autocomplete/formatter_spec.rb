require 'spec_helper'

describe Trample::Autocomplete::Formatter do

  let(:results) do
    [
      double(id: 4, uuid: 'uu1d', key_uuid: 'key_uu1d', age: '37', name: 'Homer')
    ]
  end

  let(:formatted) { formatter.format_all(results) }

  describe "#format_all" do
    context "when formatting via proc" do
      let(:formatter) do
        described_class.new(->(result) {
          {id: result.id+1, key: result.id+2, text: "proc_#{result.name}"}
        })
      end

      it "should use the proc to determine format" do
        expect(formatted).to match_array([{id: 5, key: 6, text: 'proc_Homer'}])
      end
    end

    context "when formatting via hash" do
      let(:formatter) { described_class.new(id: :uuid, key: :key_uuid, text: :age) }

      it "should use correct corresponding attrs to format" do
        expect(formatted).to match_array([{id: 'uu1d', key: 'key_uu1d', text: '37'}])
      end
    end

    context "when no format customization" do
      let(:formatter) { described_class.new }

      it "should use formatting defaults" do
        expect(formatted).to match_array([{id: 4, key: 4, text: 'Homer'}])
      end
    end

    context "when passed a user query" do
      let(:formatter) { described_class.new }
      let(:formatted) { formatter.format_all(results, user_query: 'foo') }

      it "should include the user query as the first result" do
        expect(formatted[0].to_hash.symbolize_keys)
          .to eq(id: 'foo', key: 'foo', text: '"foo"', user_query: true)
      end
    end
  end

end
