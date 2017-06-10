require 'konfa/autodoc'
require 'konfa/autodoc/rspec'

describe Konfa::AutoDoc::Markdown do
  let(:variables) { [
    Konfa::AutoDoc::Variable.new("var_1", "on", "This is an explanation"),
    Konfa::AutoDoc::Variable.new("var_2", "off", nil),
    Konfa::AutoDoc::Variable.new("var_3", "a string", "Documentation"),
    Konfa::AutoDoc::Variable.new("var_4", "nil", nil),
  ]}

  it_behaves_like 'an Konfa::AutoDoc::Formatter subclass'

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
