$: << File.join(File.dirname(File.dirname(__FILE__)), "support")

require 'konfa/autodoc'
require 'konfa/autodoc_generator/markdown'


describe Konfa::AutoDocGenerator::Markdown do
  let(:variables) { [
    Konfa::AutoDocVariable.new("var_1", "on", "This is an explanation"),
    Konfa::AutoDocVariable.new("var_2", "off", nil),
    Konfa::AutoDocVariable.new("var_3", "a string", "Documentation"),
    Konfa::AutoDocVariable.new("var_4", "nil", nil),
  ]}
  let(:konfa_class) { double("KonfaClass") }

  before(:each) do
    allow(konfa_class).to receive(:name).and_return('KonfaClass')
  end

  subject { described_class.new(konfa_class) }

  it { is_expected.to be_kind_of Konfa::AutoDocGenerator::Base }
  it { is_expected.to respond_to :konfa_class }
  it { is_expected.to respond_to :version }

  it 'sets class as r/o accessor' do
    expect(subject.konfa_class).to be konfa_class
  end

  context 'generated markdown' do
    subject { described_class.new(konfa_class).generate(variables) }

    it { is_expected.to match /^# KonfaClass\n/ }
    it { is_expected.to match /## var_1\nDefault: \*on\*\nThis is an explanation\n\n/ }
    it { is_expected.to match /## var_2\nDefault: \*off\*\n\n/ }
    it { is_expected.to match /## var_3\nDefault: \*a string\*\nDocumentation\n\n/ }
    it { is_expected.to match /## var_4\nDefault: \*nil\*\n\Z/ }
  end

  context "optional verion string" do
    let(:version) { "v2.20" }
    subject { described_class.new(konfa_class, version).generate(variables) }
    it { is_expected.to match /^# KonfaClass\n\*Version: #{version}\*\n/}
  end

end
