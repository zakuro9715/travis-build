module Travis
  module Build
    class Script
      module DirectoryCache
        module Casher

          CASHER_URL = 'https://raw.githubusercontent.com/travis-ci/casher/%s/bin/casher'
          USE_RUBY   = '1.9.3'
          BIN_PATH   = '$CASHER_DIR/bin/casher'

          CURL_FORMAT = <<-EOF
             time_namelookup:  %{time_namelookup} s
                time_connect:  %{time_connect} s
             time_appconnect:  %{time_appconnect} s
            time_pretransfer:  %{time_pretransfer} s
               time_redirect:  %{time_redirect} s
          time_starttransfer:  %{time_starttransfer} s
              speed_download:  %{speed_download} bytes/s
               url_effective:  %{url_effective}
                             ----------
                  time_total:  %{time_total} s
          EOF

          def install
            sh.export 'CASHER_DIR', '$HOME/.casher'

            sh.mkdir '$CASHER_DIR/bin', echo: false, recursive: true
            sh.cmd "curl #{casher_url} #{debug_flags} -L -o #{BIN_PATH} -s --fail", retry: true, echo: 'Installing caching utilities'
            sh.raw "[ $? -ne 0 ] && echo 'Failed to fetch casher from GitHub, disabling cache.' && echo > #{BIN_PATH}"

            sh.if "-f #{BIN_PATH}" do
              sh.chmod '+x', BIN_PATH, assert: false, echo: false
            end
          end

          def fold(message = nil)
            @fold_count ||= 0
            @fold_count  += 1

            sh.fold "cache.#{@fold_count}" do
              sh.echo message if message
              yield
            end
          end

          def casher_url
            CASHER_URL % casher_branch
          end

          def casher_branch
            if branch = data.cache[:branch]
              branch
            else
              data.cache?(:edge) ? 'master' : 'production'
            end
          end

          def run(command, args, options = {})
            sh.if "-f #{BIN_PATH}" do
              sh.cmd "rvm #{USE_RUBY} --fuzzy do #{BIN_PATH} #{command} #{Array(args).join(' ')}", options.merge(echo: false)
            end
          end

          def debug_flags
            "-v -w '#{CURL_FORMAT}'" if data.cache[:debug]
          end
        end
      end
    end
  end
end