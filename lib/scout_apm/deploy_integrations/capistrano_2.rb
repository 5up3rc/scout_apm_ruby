require 'scout_apm'

module ScoutApm
  module DeployIntegrations
    class Capistrano2
      attr_reader :logger

      def initialize(logger)
        @logger = logger
        @cap = ObjectSpace.each_object(Capistrano::Configuration).map.first rescue nil
      end

      def name
        :capistrano_2
      end

      def version
        present? ? Capistrano::VERSION : nil
      end

      def present?
        if !@cap.nil? && @cap.is_a?(Capistrano::Configuration)
          require 'capistrano/version'
          defined?(Capistrano::VERSION) && Gem::Dependency.new('', '~> 2.0').match?('', Capistrano::VERSION.to_s)
        else
          return false
        end
        return true
      rescue
        return false
      end

      def install
        logger.debug "Initializing Capistrano2 Deploy Integration."
        @cap.load File.expand_path("../capistrano_2.cap", __FILE__)
      end

      def root
        '.'
      end

      def env
        @cap.fetch(:stage)
      end

      def found?
        true
      end

      def report
        payload = ScoutApm::Serializers::PayloadSerializer.serialize_deploy(deploy_data)
        reporter.report(payload, {'Content-Type' => 'application/x-www-form-urlencoded'})
      end

      def reporter
        @reporter ||= ScoutApm::Reporter.new(:deploy_hook, ScoutApm::Agent.instance.config, @logger)
      end

      def deploy_data
        {:revision => current_revision, :branch => branch, :deployed_by => deployed_by}
      end

      def branch
        @cap.fetch(:branch)
      end

      def current_revision
        @cap.fetch(:current_revision) || `git rev-list --max-count=1 --abbrev-commit --abbrev=12 #{branch}`.chomp
      end

      def deployed_by
        ScoutApm::Agent.instance.config.value('deployed_by')
      end

    end
  end
end