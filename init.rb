module Travis
  module CLI
    class Compile < RepoCommand
      description "compiles a build script from .travis.yml"

      attr_accessor :slug, :source_url

      def setup
        error "run command is not available on #{RUBY_VERSION}" if RUBY_VERSION < '1.9.3'
        $:.unshift File.expand_path('../lib', __FILE__)
        require 'travis/build'
      end

      def find_source_url
          git_head    = `git name-rev --name-only HEAD 2>#{IO::NULL}`.chomp
          git_remote  = `git config --get branch.#{git_head}.remote 2>#{IO::NULL}`.chomp
          return `git ls-remote --get-url #{git_remote} 2>#{IO::NULL}`.chomp
      end

      def run(*arg)
        @slug = find_slug
        @source_url = find_source_url
        if match_data = /\A(?<build>\d+)(\.(?<job>\d+))?\z/.match(arg.first)
          set_up_config(match_data)
        elsif arg.length > 0
          warn "#{arg.first} does not look like a job number. Last build's first job is assumed."
          @config = last_build.jobs[0].config
        else
          ## No arg case; use .travis.yml from $PWD
          config = travis_config

          global_env = sanitize_global_env(config)

          if config.has_key? 'matrix'
            warn 'matrix key is ignored'
            config.delete_if { |k,v| k == 'matrix' }
          end

          unless config['os'].respond_to? :scan
            warn "'os' key is unsupported in local build script compilation. Setting to default, 'linux'."
            config['os'] = 'linux'
          end

          set_up_env(config, global_env)
        end

        puts Travis::Build.script(data).compile(true)
      end

      private
        def data
          {
            :config => @config,
            :repository => {
              :slug => slug,
              :source_url => source_url
            }
          }
        end

        def set_up_config(match_data)
          @build = build(match_data[:build])
          @job_number = match_data[:job].to_i - 1
          @config = @build.jobs[@job_number].config
        end

        def sanitize_global_env(config)
          global_env = []
          if config.has_key? 'env'
            if config['env']['matrix']
              warn 'env.matrix key is ignored'
            end
            global_env = config['env'].fetch('global', [])
            global_env.delete_if { |v| v.is_a? Hash }
          end

          global_env
        end

        def set_up_env(config, global_env)
          @config = config.delete_if {|k,v| k == 'env' }
          @config['env'] = global_env
        end
    end
  end
end
