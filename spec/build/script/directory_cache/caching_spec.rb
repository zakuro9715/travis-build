require 'spec_helper'

describe Travis::Build::Script::DirectoryCache::Caching, :sexp do
  let(:jwt_options)    { { issuer: 'test_issuer', secret: 'superduper' } }
  let(:cache_options) { { fetch_timeout: 20, push_timeout: 30, type: 'caching', jwt: jwt_options } }
  let(:data)          { PAYLOADS[:push].deep_merge(config: config, cache_options: cache_options, job: { branch: branch, pull_request: pull_request }) }
  let(:config)        { {} }
  let(:pull_request)  { nil }
  let(:branch)        { 'master' }
  let(:sh)            { Travis::Shell::Builder.new }
  let(:cache)         { described_class.new(sh, Travis::Build::Data.new(data), 'ex a/mple', Time.at(10)) }
  let(:subject)       { sh.to_sexp }

  describe 'setup' do
    before do
      cache.setup
    end
    it { should include_sexp :cmd }
  end
end
