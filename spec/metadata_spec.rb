require 'spec_helper'

RSpec.describe Trample::Metadata::Pagination do

  describe "#next?" do
    context "when current_page is not last page" do
      subject { described_class.new(total: 100, current_page: 2, per_page: 10).next? }
      it { is_expected.to be_truthy }
    end

    context "when current_page is last page" do
      subject { described_class.new(total: 20, current_page: 2, per_page: 10).next? }
      it { is_expected.to be_falsy }
    end
  end
end
