require 'scout_apm/environment'

# Given a call stack Array, grabs the first +APP_FRAMES+ callers within the
# application root directory.
#
module ScoutApm
  module Utils
    class BacktraceParser

      APP_FRAMES = 3 # will return up to 3 frames from the app stack.

      attr_reader :call_stack

      def initialize(call_stack, root=ScoutApm::Environment.instance.root)
        @call_stack = call_stack
        # We can't use a constant as it'd be too early to fetch environment info
        #
        # This regex looks for files under the app root, inside lib/, app/, and
        # config/ dirs, and captures the path under root.
        @@app_dir_regex = %r[#{root}/((?:lib/|app/|config/).*)]
      end

      def call
        stack = []
        call_stack.each do |c|
          if m = c.match(@@app_dir_regex)
            stack << m[1]
            break if stack.size == APP_FRAMES
          end
        end
        stack
      end
    end
  end
end
