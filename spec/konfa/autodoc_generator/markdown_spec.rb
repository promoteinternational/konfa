$: << File.join(File.dirname(File.dirname(__FILE__)), "support")

require 'konfa/autodoc'
require 'konfa/autodoc_generator/markdown'


RSpec.shared_examples 'an AutoDoc::Generator subclass' do
  let(:konfa_class) { double("KonfaClass") }

  subject { described_class.new(konfa_class) }

  it { is_expected.to be_kind_of Konfa::AutoDocGenerator::Base }
  it { is_expected.to respond_to :konfa_class }
  it { is_expected.to respond_to :version }

  it 'sets class as r/o accessor' do
    expect(subject.konfa_class).to be konfa_class
  end

  it 'sets version as r/w accessor' do
    expect(subject).to respond_to :version=
  end

  context '#generate' do
    let(:autodoc_instance) { double }

    before(:each) do
      allow(Konfa::AutoDoc).to receive(:new).with(subject.konfa_class).and_return autodoc_instance
      allow(subject).to receive(:format).and_return "something formatted"
      allow(autodoc_instance).to receive(:parse).and_return "something parsed"
    end

    after(:each) do
      subject.generate
    end

    it 'constructs a parser with konfa_class' do
      expect(Konfa::AutoDoc).to receive(:new).with(subject.konfa_class).and_return autodoc_instance
    end

    it 'passes the parsed value to #format' do
      expect(subject).to receive(:format).with("something parsed")
    end
  end
end

describe Konfa::AutoDocGenerator::Markdown do
  let(:variables) { [
    Konfa::AutoDocVariable.new("var_1", "on", "This is an explanation"),
    Konfa::AutoDocVariable.new("var_2", "off", nil),
    Konfa::AutoDocVariable.new("var_3", "a string", "Documentation"),
    Konfa::AutoDocVariable.new("var_4", "nil", nil),
  ]}

  it_behaves_like 'an AutoDoc::Generator subclass'

  describe '#format' do
    let(:konfa_class) { double("KonfaClass", name: 'KonfaClass') }
    let(:instance) { described_class.new(konfa_class) }

    subject { instance.format(variables) }

    it { is_expected.to match /^# KonfaClass\n/ }
    it { is_expected.to match /## var_1\n\nDefault: \*on\*\n\nThis is an explanation\n\n/ }
    it { is_expected.to match /## var_2\n\nDefault: \*off\*\n\n/ }
    it { is_expected.to match /## var_3\n\nDefault: \*a string\*\n\nDocumentation\n\n/ }
    it { is_expected.to match /## var_4\n\nDefault: \*nil\*\Z/ }
    it { is_expected.to_not match /\n\*Version: v1.2.3\*\n/ }

    context 'with version attribute' do
      before(:each) do
        instance.version = "v1.2.3"
      end

      it { is_expected.to match /\n\*Version: v1.2.3\*\n/ }
    end
  end
end
