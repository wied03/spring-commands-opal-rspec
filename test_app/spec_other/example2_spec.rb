describe 'a partially passing spec' do
  it 'runs successfully' do
    'I run'.should =~ /run/
  end

  it 'fails' do
    expect(true).to eq false
  end
end
