# encoding: utf-8
require "logstash/devutils/rspec/spec_helper"
require "logstash/inputs/ganglia"
require_relative "support/client"

class GangliaHelpers

  def setup_clients(number_of_clients, port)
    number_of_clients.times.inject([]) do |clients|
      clients << GangliaClient.new(localhost, port)
    end
  end

end
