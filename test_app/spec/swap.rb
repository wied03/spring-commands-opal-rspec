describe 'a running spec' do
  it 'runs successfully' do
    'I run'.should =~ /run/
  end

  it 'passes' do
    expect(true).to be_truthy
  end
end
