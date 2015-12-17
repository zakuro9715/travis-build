shared_examples_for 'fix hostname' do
  let(:limit_hostname_length) { "sudo -u root hostname \"$(hostname | cut -d. -f1 | cut -d\- -f1-2)-job-1-$(hostname -f | cut -d. -f2-5)\"" }

  it 'adds an sexp to shorten hostname' do
    should include_sexp [:raw, limit_hostname_length]
  end
end
