require 'travis/build/appliances/base'

module Travis
  module Build
    module Appliances
      class LimitHostnameLength < Base
        def_delegators :data, :job

        def apply
          sh.raw "sudo -u root hostname \"$(hostname -f | cut -d. -f1 | cut -d\\\\- -f1-2)-job-#{job[:id]}-$(hostname -f | cut -d. -f2-5)\""
          sh.raw "sed -e \"s/^\\(127\\.0\\.0\\.1.*\\)/\\1 $(hostname -f | cut -d. -f1 | cut -d\\\\- -f1-2)-job-#{job[:id]}-$(hostname -f | cut -d. -f2-5)/\" /etc/hosts | sudo tee /etc/hosts"
        end
      end
    end
  end
end
