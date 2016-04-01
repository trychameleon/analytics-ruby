require 'segment_io/analytics/defaults'
require 'segment_io/analytics/utils'
require 'segment_io/analytics/version'
require 'segment_io/analytics/client'
require 'segment_io/analytics/worker'
require 'segment_io/analytics/request'
require 'segment_io/analytics/response'
require 'segment_io/analytics/logging'

module SegmentIo
  class Analytics
    def initialize options = {}
      Request.stub = options[:stub] if options.has_key?(:stub)
      @client = SegmentIo::Analytics::Client.new options
    end

    def method_missing message, *args, &block
      if @client.respond_to? message
        @client.send message, *args, &block
      else
        super
      end
    end

    def respond_to? method_name, include_private = false
      @client.respond_to?(method_name) || super
    end

    include Logging
  end
end
