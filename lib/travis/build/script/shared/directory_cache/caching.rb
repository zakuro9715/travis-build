require 'shellwords'
require 'travis/build/script/shared/directory_cache/casher'

module Travis
  module Build
    class Script
      module DirectoryCache
        class Caching
          include Casher
          require 'jwt'
          require 'json'

          attr_reader :sh, :data, :slug, :start, :msgs

          def initialize(sh, data, slug, start = Time.now)
            @sh = sh
            @data = data
            @slug = slug
            @start = start
            @msgs = []
          end

          def fetch
            run('fetch', url, timing: true)
          end

          def push
            run('push', url, assert: false, timing: true)
          end

          def valid?
            !!jwt_options[:issuer] && !!jwt_options[:secret] && !!token
          end

          def directories
            Array(data.cache[:directories])
          end

          private
          def token
            return @token if @token

            payload = <<-EOF
            {
              "iss": "#{jwt_options[:issuer]}",
              "jti": "",
              "iat": #{Time.now.to_i},
              "exp": #{Time.now.to_i + 300},
              "payload": {
                "repo_slug": "#{data.slug}",
                "repo_id": #{data.github_id},
                "branch": "#{data.branch}",
                "backend": "s3",
                "cache_slug": "#{slug}"
              }
            }
            EOF

            @token = JWT.encode(JSON.parse(payload), jwt_options[:secret], 'HS256')
          end

          def url
            "https://caching-staging.travis-ci.org/cache?token=" << token
          end

          def jwt_options
            options[:jwt] || {}
          end

          def options
            data.cache_options || {}
          end

        end
      end
    end
  end
end
