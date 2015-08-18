# encoding: utf-8
require "socket"
require "gmetric"

class GangliaClient

  attr_reader :addr, :port, :socket

  def initialize(addr, port)
    @addr   = addr
    @port   = port
    @socket = UDPSocket.new
    socket.connect(addr, port)
  end

  def send(data={})
    g = Ganglia::GMetric.pack(data)
    @socket.send(g[0], 0)
    @socket.send(g[1], 0)
  end
end
