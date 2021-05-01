module KinesisToKafka
  LOGGER = Logger.new('log.log')

  def self.root
    Pathname.new(File.expand_path '../..', __FILE__)
  end
end

require_relative 'kinesis_to_kafka/kinesis_properties'
require_relative 'kinesis_to_kafka/kinesis_consumer'
require_relative 'kinesis_to_kafka/kafka_producer'
