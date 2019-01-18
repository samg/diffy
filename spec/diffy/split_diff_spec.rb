require 'rspec'

describe Diffy::SplitDiff do
  before do
    ::Diffy::Diff.default_options.merge!(diff: '-U10000')
  end

  it 'fail with invalid format' do
    expected_fail = expect do
      described_class.new("lorem\n", "ipsum\n", format: :fail)
    end
    expected_fail.to raise_error(ArgumentError)
  end

  describe '#left' do
    it 'only highlight deletions' do
      string1 = "lorem\nipsum\ndolor\nsit amet\n"
      string2 = "lorem\nipsumdolor\nsit amet\n"
      expect(described_class.new(string1, string2).left).to eq <<-TEXT
 lorem
-ipsum
-dolor
 sit amet
      TEXT
    end

    it 'also format left diff as html' do
      string1 = "lorem\nipsum\ndolor\nsit amet\n"
      string2 = "lorem\nipsumdolor\nsit amet\n"
      expect(described_class.new(string1, string2, format: :html).left).to eq <<-HTML
<div class="diff">
  <ul>
    <li class="unchanged"><span>lorem</span></li>
    <li class="del"><del>ipsum<strong></strong></del></li>
    <li class="del"><del><strong></strong>dolor</del></li>
    <li class="unchanged"><span>sit amet</span></li>
  </ul>
</div>
      HTML
    end
  end

  describe '#right' do
    it 'only highlight insertions' do
      string1 = "lorem\nipsum\ndolor\nsit amet\n"
      string2 = "lorem\nipsumdolor\nsit amet\n"
      expect(described_class.new(string1, string2).right).to eq <<-TEXT
 lorem
+ipsumdolor
 sit amet
      TEXT
    end

    it 'also format right diff as html' do
      string1 = "lorem\nipsum\ndolor\nsit amet\n"
      string2 = "lorem\nipsumdolor\nsit amet\n"
      expect(described_class.new(string1, string2, format: :html).right).to eq <<-HTML
<div class="diff">
  <ul>
    <li class="unchanged"><span>lorem</span></li>
    <li class="ins"><ins>ipsumdolor</ins></li>
    <li class="unchanged"><span>sit amet</span></li>
  </ul>
</div>
      HTML
    end
  end
end
