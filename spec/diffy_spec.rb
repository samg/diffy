require 'rspec'

describe Diffy do
  it 'be some css' do
    expect(described_class::CSS).to include 'diff{overflow:auto;}'
  end
end
