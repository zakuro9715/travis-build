require 'shellwords'

require 'travis/build/script/shared/directory_cache/s3/aws4_signature'
require 'travis/build/script/shared/directory_cache/casher'

module Travis
  module Build
    class Script
      module DirectoryCache
        class S3
          include Casher

          MSGS = {
            config_missing: 'Worker S3 config missing: %s'
          }

          VALIDATE = {
            bucket:            'bucket name',
            access_key_id:     'access key id',
            secret_access_key: 'secret access key'
          }

          KeyPair = Struct.new(:id, :secret)

          Location = Struct.new(:scheme, :region, :bucket, :path) do
            def hostname
              "#{bucket}.#{region == 'us-east-1' ? 's3' : "s3-#{region}"}.amazonaws.com"
            end
          end

          attr_reader :sh, :data, :slug, :start, :msgs

          def initialize(sh, data, slug, start = Time.now)
            @sh = sh
            @data = data
            @slug = slug
            @start = start
            @msgs = []
          end

          def valid?
            validate
            msgs.empty?
          end

          def fetch
            urls = [
              Shellwords.escape(fetch_url(group, '.tgz').to_s),
              Shellwords.escape(fetch_url.to_s)
            ]
            if data.pull_request
              urls << Shellwords.escape(fetch_url(data.branch, '.tgz').to_s)
              urls << Shellwords.escape(fetch_url(data.branch).to_s)
            end
            if data.branch != 'master'
              urls << Shellwords.escape(fetch_url('master', '.tgz').to_s)
              urls << Shellwords.escape(fetch_url('master').to_s)
            end
            run('fetch', urls, timing: true)
          end

          def push
            run('push', Shellwords.escape(push_url.to_s), assert: false, timing: true)
          end

          def fetch_url(branch = group, ext = '.tbz')
            url('GET', prefixed(branch, ext), expires: fetch_timeout)
          end

          def push_url(branch = group)
            url('PUT', prefixed(branch, '.tgz'), expires: push_timeout)
          end

          private

            def validate
              VALIDATE.each { |key, msg| msgs << msg unless s3_options[key] }
              sh.echo MSGS[:config_missing] % msgs.join(', '), ansi: :red unless msgs.empty?
            end

            def group
              data.pull_request ? "PR.#{data.pull_request}" : data.branch
            end

            def directories
              Array(data.cache[:directories])
            end

            def fetch_timeout
              options.fetch(:fetch_timeout)
            end

            def push_timeout
              options.fetch(:push_timeout)
            end

            def location(path)
              Location.new(
                s3_options.fetch(:scheme, 'https'),
                s3_options.fetch(:region, 'us-east-1'),
                s3_options.fetch(:bucket),
                path
              )
            end

            def prefixed(branch, ext = '.tgz')
              args = [data.github_id, branch, slug].compact
              args.map! { |arg| arg.to_s.gsub(/[^\w\.\_\-]+/, '') }
              '/' << args.join('/') << ext
            end

            def url(verb, path, options = {})
              AWS4Signature.new(key_pair, verb, location(path), options[:expires], start).to_uri.to_s.untaint
            end

            def key_pair
              KeyPair.new(s3_options[:access_key_id], s3_options[:secret_access_key])
            end

            def s3_options
              options[:s3] || {}
            end

            def options
              data.cache_options || {}
            end
        end
      end
    end
  end
end
