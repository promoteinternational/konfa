require 'spec_helper'

describe Konfa::Deprecation do
  let(:klass) do
    Class.new do
      include Konfa::Deprecation
    end
  end

  before(:each) { klass.deprecation_warnings = true }

  describe '.deprecation_warnings=' do
    subject { klass.deprecation_warnings = false }

    it 'sets deprecation_warnings' do
      subject
      expect(klass.deprecation_warnings).to be false
    end
  end

  describe '.deprecation_warnings' do
    subject { klass.deprecation_warnings }

    context 'when class attribute is set' do
      before(:each) { klass.deprecation_warnings = false }

      it { is_expected.to be false }
    end
  end

  describe '.deprecated' do
    before(:each) { allow(klass).to receive(:warn).and_return(nil) }

    subject { klass.deprecated('foo', 'bar') }

    it { is_expected.to be nil }

    it 'delegates to warn' do
      expect(klass).to receive(:warn).with('foo', 'bar')
      subject
    end

    context 'when deprecation_warnings is set to false' do
      before(:each) { klass.deprecation_warnings = false }

      it 'does not call warn' do
        expect(klass).not_to receive(:warn)
        subject
      end
    end
  end
end
