module KinesisToKafka
  class KafkaProducer
    APPLICATION_ID = ENV.fetch('KAFKA_APPLICATION_ID', 'my-application')
    TOPIC = ENV.fetch('KAFKA_TOPIC', 'test')
    TOPIC_PARTITIONS = ENV.fetch('KAFKA_TOPIC_PARTITIONS', 100).to_i
    TOPIC_REPLICATION_FACTOR = ENV.fetch('KAFKA_TOPIC_REPLICATION_FACTOR', 2).to_i
    BROKER_URLS = ENV['KAFKA_BROKER_URLS'].yield_self { |v| v.split(/\s*,\s*/) if v && !v.empty? }
    AWS_CLUSTER_NAME = ENV['KAFKA_AWS_CLUSTER_NAME'].yield_self { |v| v if v && !v.empty? }

    if [AWS_CLUSTER_NAME, BROKER_URLS].compact.length != 1
      raise 'One of KAFKA_AWS_CLUSTER_NAME or KAFKA_BROKER_URLS must be provided'
    end

    def handle_records(records)
      LOGGER.info records

      records.each do |record|
        producer.produce(
          record.fetch(:data),
          partition_key: record.fetch(:partition_key),
          topic: TOPIC,
          headers: {
            kinesis_approximate_arrival_timestamp: record.fetch(:approximate_arrival_timestamp),
            kinesis_sequence_number: record.fetch(:sequence_number),
            kinesis_subsequence_number: record.fetch(:subsequence_number),
          },
        )
      end

      producer.deliver_messages
    rescue Kafka::UnknownTopicOrPartition
      initialize_topic
      retry
    end

    private

    def kafka
      @kafka ||= Kafka.new(broker_urls, client_id: APPLICATION_ID, ssl_ca_certs_from_system: use_ssl?)
    end

    def producer
      @producer ||= kafka.producer
    end

    def initialize_topic
      kafka.create_topic(
        TOPIC,
        num_partitions: TOPIC_PARTITIONS,
        replication_factor: TOPIC_REPLICATION_FACTOR,
      )
    rescue Kafka::TopicAlreadyExists
    end

    def broker_urls
      return BROKER_URLS if BROKER_URLS

      aws_kafka_client = Aws::Kafka::Client.new

      cluster = aws_kafka_client.list_clusters(
        cluster_name_filter: AWS_CLUSTER_NAME,
        max_results: 1
      ).cluster_info_list.first

      aws_kafka_client.get_bootstrap_brokers(
        cluster_arn: cluster.cluster_arn
      ).bootstrap_broker_string_tls.split(',')
    end

    def use_ssl?
      !AWS_CLUSTER_NAME.nil?
    end
  end
end
