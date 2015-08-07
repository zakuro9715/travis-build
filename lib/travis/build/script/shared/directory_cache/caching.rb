require 'shellwords'
require 'travis/build/script/shared/directory_cache/casher'

module Travis
  module Build
    class Script
      module DirectoryCache
        class Caching
          include Casher
          require 'jwt'

          attr_reader :sh, :data, :slug, :start, :msgs

          def initialize(sh, data, slug, start = Time.now)
            @sh = sh
            @data = data
            @slug = slug
            @start = start
            @msgs = []
          end

          def setup
            fold 'Setting up build cache' do
              install
              fetch
              add(directories) if data.cache?(:directories)
            end
          end

          def fetch
            run('fetch', url, timing: true)
          end

          def push
            run('push', url, assert: false, timing: true)
          end

          def add(*paths)
            if paths
              paths.flatten.each_slice(ADD_DIR_MAX) { |dirs| run('add', dirs) }
            end
          end

          def valid?
            true
          end

          def directories
            Array(data.cache[:directories])
          end

          private
          def url
            payload = <<-EOF
            {
              "iss": "#{ENV['JWT_ISSUER']}",
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

            token = JWT.encode(payload, ENV['JWT_SECRET'], 'HS256')
            "https://caching-staging.travis-ci.org/cache?token=" << token
          end

        end
      end
    end
  end
end
