# encoding: utf-8
require "logstash/devutils/rspec/spec_helper"
require "logstash/inputs/ganglia"
require_relative "support/client"

module GangliaHelpers

  def setup_clients(number_of_clients, port)
    number_of_clients.times.inject([]) do |clients|
      clients << GangliaClient.new(localhost, port)
    end
  end

  def self.input(config, size, &block)
    pipeline = LogStash::Pipeline.new(config)
    queue = Queue.new

    pipeline.instance_eval do
      # create closure to capture queue
      @output_func = lambda { |event| queue << event }

      # output_func is now a method, call closure
      def output_func(event)
        @output_func.call(event)
      end
    end

    pipeline_thread = Thread.new { pipeline.run }
    sleep 0.1 while !pipeline.ready?

    block.call
    sleep 0.1 while queue.size != size

    result = size.times.inject([]) do |acc|
      acc << queue.pop
    end

    pipeline.shutdown
    pipeline_thread.join

    result
  end # def input

end
