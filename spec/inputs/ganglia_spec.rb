# encoding: utf-8
require_relative "../spec_helper"
require "logstash/plugin"
require "logstash/event"

describe LogStash::Inputs::Ganglia do

  let(:properties) { {:name => "foo" } }
  let(:event)      { LogStash::Event.new(properties) }

  it "should register without errors" do
    plugin = LogStash::Plugin.lookup("input", "ganglia").new({})
    expect { plugin.register }.to_not raise_error
  end

  describe "when interrupting the plugin" do
    it_behaves_like "an interruptible input plugin" do
      let(:config) { {} }
    end
  end

  describe "connection" do
    let(:nevents)  { 10 }
    let(:port)     { rand(1000)+1025 }

    let(:conf) do
      <<-CONFIG
        input {
          ganglia {
            port => #{port}
         }
       }
      CONFIG
    end
    let(:data) do
      {  :name => 'pageviews',
         :units => 'req/min',
         :type => 'uint8',
         :value => 7000,
         :tmax => 60,
         :dmax => 300,
         :group => 'test' }
    end

    let(:client) { GangliaClient.new("0.0.0.0", port) }

    let(:events) do
      input(conf, nevents) do
        nevents.times do |value|
          client.send(data)
        end
      end
    end

    let(:event) { events[0] }

    it "should receive and generate proper number of events" do
      expect(events.count).to be(nevents)
    end

    it "should receive the correct data" do
      expect(event["tmax"]).to eq(60)
    end

  end
end
