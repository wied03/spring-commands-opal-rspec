describe 'foobar' do
  subject { true }

  context 'succeeds' do
    it { is_expected.to eq true }
  end

  context 'fails' do
    it { is_expected.to eq false }
  end
end
