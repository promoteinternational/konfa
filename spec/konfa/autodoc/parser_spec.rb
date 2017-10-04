$: << File.join(File.dirname(File.dirname(__FILE__)), "../support")

require 'konfa_subclasses'
require 'konfa/autodoc'

RSpec.shared_context 'parse test class' do |klass, expected_elements|
  before {
    @konfa_class = klass
    @size = expected_elements
  }

  let(:instance) { Konfa::AutoDoc::Parser.new(@konfa_class) }
  subject { instance.parse }
  it { is_expected.to all( be_a Struct )}

  it "has #{@size} elements" do
    expect(subject.size).to eq @size
  end
end


describe Konfa::AutoDoc::Parser do
  context 'initialization' do
    subject { described_class.new(KonfaBasic) }

    it 'implements konfa_class r/o accessor' do
      expect(subject.konfa_class).to eq KonfaBasic
      expect(subject).to_not respond_to(:konfa_class=)

    end

    it 'implements variables r/o accessor' do
      expect(subject.variables).to eq []
      expect(subject).to_not respond_to(:variables=)
    end
  end

  context 'parse' do
    include_context 'parse test class', KonfaBasic, 2

    it { is_expected.to be_an(Array) }
    it { is_expected.to eq instance.variables }

    context 'returned data structure' do
      subject { instance.parse.first }

      it {
        is_expected.to have_attributes(
          name: 'my_var',
          default: 'default value',
          comment: 'This is a variable'
        )
      }
    end

    it 'resets data structure between calls' do
      first = instance.parse
      second = instance.parse

      expect(first).to eq second
      expect(first).to_not be second
      expect(instance.variables).to be second
    end
  end

  context 'parse one-line hash declaration' do
    include_context 'parse test class', KonfaOneLineHash, 2

    it 'found the expect data' do
      expect(subject[0]).to have_attributes(name: 'my_var_1', default: 'default value', comment: nil)
      expect(subject[1]).to have_attributes(name: 'my_var_2', default: "nil", comment: nil)
    end
  end

  context 'parse mixed newline hash declaration' do
    include_context 'parse test class', KonfaMixedNewlines, 4

    it 'found the expect data' do
      expect(subject[0]).to have_attributes(name: 'my_var_1', default: 'var 1', comment: nil)
      expect(subject[1]).to have_attributes(name: 'my_var_2', default: "var 2", comment: nil)
      expect(subject[2]).to have_attributes(name: 'my_var_3', default: "nil", comment: nil)
      expect(subject[3]).to have_attributes(name: 'my_var_4', default: "var 4", comment: nil)
    end
  end

  context 'parse multiple hash declarations' do
    include_context 'parse test class', KonfaMultipleHashes, 4

    it 'found the expect data' do
      expect(subject[0]).to have_attributes(name: 'my_var_1', default: 'default value', comment: nil)
      expect(subject[1]).to have_attributes(name: 'my_var_2', default: "nil", comment: 'Some comment here that continues')
      expect(subject[2]).to have_attributes(name: 'my_var_3', default: "value 3", comment: 'Comment here')
      expect(subject[3]).to have_attributes(name: 'my_var_4', default: "value 4", comment: nil)
    end
  end

  context "parse mixed key declaration styles" do
    include_context 'parse test class', KonfaMixedKeyStyles, 3

    it 'found the expect data' do
      expect(subject[0]).to have_attributes(name: 'new_style', default: 'default value', comment: 'This is a variable')
      expect(subject[1]).to have_attributes(name: 'old_style', default: "also default", comment: 'This is documented')
      expect(subject[2]).to have_attributes(name: 'also_new', default: "Hey", comment: nil)
    end
  end

  context "parse values that are barewords" do
    include_context 'parse test class', KonfaBarewordAssignments, 6

    it 'found the expect data' do
      expect(subject[0]).to have_attributes(name: 'my_var_1', default: 'nil', comment: nil)
      expect(subject[1]).to have_attributes(name: 'my_var_2', default: "method_call", comment: nil)
      expect(subject[2]).to have_attributes(name: 'my_var_3', default: "@variable", comment: nil)
      expect(subject[3]).to have_attributes(name: 'my_var_4', default: "@@class_variable", comment: 'Comment here')
      expect(subject[4]).to have_attributes(name: 'my_var_5', default: "KonfaBarewordAssignments::A_CONSTANT", comment: nil)
      expect(subject[5]).to have_attributes(name: 'my_var_6', default: "KonfaBarewordAssignments.method_call", comment: nil)
    end
  end

  context "parse declarations with blank lines" do
    include_context 'parse test class', KonfaBlankLines, 4

    it 'found the expect data' do
      expect(subject[0]).to have_attributes(name: 'my_var_1', default: "var 1", comment: "Comment 1")
      expect(subject[1]).to have_attributes(name: 'my_var_2', default: "var 2", comment: "Comment 2")
      expect(subject[2]).to have_attributes(name: 'my_var_3', default: "var 3", comment: "Comment 3")
      expect(subject[3]).to have_attributes(name: 'my_var_4', default: "var 4", comment: "Comment 4")
    end
  end

  context "no allowed_variables method in sub class" do
    let(:instance) { described_class.new(KonfaNoVariablesMethod) }
    subject { instance.parse }
    it { is_expected.to eq [] }
  end

  context "parse declarations multiline comments" do
    include_context 'parse test class', KonfaMultiLineComments, 5

    it 'found the expect data' do
      expect(subject[0]).to have_attributes(name: 'my_var_1', default: "var 1", comment: "Comment 1")
      expect(subject[1]).to have_attributes(name: 'my_var_2', default: "var 2", comment: "Comment 2... ...continues here")
      expect(subject[2]).to have_attributes(name: 'my_var_3', default: "var 3", comment: "Comment 3 Here is an off comment")
      expect(subject[3]).to have_attributes(name: 'my_var_4', default: "false", comment: "If true: this is on If false: this is off")
      expect(subject[4]).to have_attributes(name: 'my_var_5', default: 'var 5', comment: 'This :comment => looks like a hash declaration')
    end
  end
end
