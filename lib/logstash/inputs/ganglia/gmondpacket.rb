# encoding: utf-8
# Inspiration
# https://github.com/fastly/ganglia/blob/master/lib/gm_protocol.x
# https://github.com/igrigorik/gmetric/blob/master/lib/gmetric.rb
# https://github.com/ganglia/monitor-core/blob/master/gmond/gmond.c#L1211
# https://github.com/ganglia/ganglia_contrib/blob/master/gmetric-python/gmetric.py#L107
# https://gist.github.com/1377993
# http://rubyforge.org/projects/ruby-xdr/

require 'logstash/inputs/ganglia/xdr'
require 'stringio'

class GmonPacket

  def initialize(packet)
    @xdr=XDR::Reader.new(StringIO.new(packet))

    # Read packet type
    type=@xdr.uint32
    case type
    when 128
      @type=:meta
    when 132
      @type=:heartbeat
    when 133..134
      @type=:data
    when 135
      @type=:gexec
    else
      @type=:unknown
    end
  end

  def heartbeat?
    @type == :hearbeat
  end

  def data?
    @type == :data
  end

  def meta?
    @type == :meta
  end

  # Parsing a metadata packet : type 128
  def parse_metadata
    meta=Hash.new
    meta['hostname']=@xdr.string
    meta['name']=@xdr.string
    meta['spoof']=@xdr.uint32
    meta['type']=@xdr.string
    meta['name2']=@xdr.string
    meta['units']=@xdr.string
    slope=@xdr.uint32

    case slope
    when 0
      meta['slope']= 'zero'
    when 1
      meta['slope']= 'positive'
    when 2
      meta['slope']= 'negative'
    when 3
      meta['slope']= 'both'
    when 4
      meta['slope']= 'unspecified'
    end

    meta['tmax']=@xdr.uint32
    meta['dmax']=@xdr.uint32
    nrelements=@xdr.uint32
    meta['nrelements']=nrelements
    unless nrelements.nil?
      extra={}
      for i in 1..nrelements
        name=@xdr.string
        extra[name]=@xdr.string
      end
      meta['extra']=extra
    end
    return meta
  end

  # Parsing a data packet : type 133..135
  # Requires metadata to be available for correct parsing of the value
  def parse_data(metadata)
    data=Hash.new
    data['hostname']=@xdr.string

    metricname=@xdr.string
    data['name']=metricname

    data['spoof']=@xdr.uint32
    data['format']=@xdr.string

    metrictype=name_to_type(metricname,metadata)

    if metrictype.nil?
      # Probably we got a data packet before a metadata packet
      #puts "Received datapacket without metadata packet"
      return nil
    end

    data['val']=parse_value(metrictype)

    # If we received a packet, last update was 0 time ago
    data['tn']=0
    return data
  end

  # Parsing a specific value of type
  # https://github.com/ganglia/monitor-core/blob/master/gmond/gmond.c#L1527
  def parse_value(type)
	# We does not need to parse data by type because it receive data as string
	# https://github.com/ganglia/monitor-core/blob/c74feb0e96d5a3efc3c788b37c113520234ab717/gmond/gmond.c#L1796
	# https://github.com/ganglia/ganglia_contrib/blob/master/gmetric-python/gmetric.py#L138
	# https://github.com/ganglia/ganglia_contrib/blob/master/gmetric-java/src/java/info/ganglia/metric/type/GMetricFloat.java#L97
    local_value=@xdr.string

    value=:unknown
    case type
    when "int16"
      value=local_value.to_i
    when "uint16"
      value=local_value.to_i
    when "uint32"
      value=local_value.to_i
    when "int32"
      value=local_value.to_i
    when "float"
      value=local_value.to_f
    when "double"
      value=local_value.to_f
    when "string"
      value=local_value
    else
      #puts "Received unknown type #{type}"
    end
    return value
  end

  # Does lookup of metricname in metadata table to find the correct type
  def name_to_type(name,metadata)
    # Lookup this metric metadata
    meta=metadata[name]
    return nil if meta.nil?

    return meta['type']
  end

end
