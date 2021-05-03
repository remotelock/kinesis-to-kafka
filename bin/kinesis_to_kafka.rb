#!/usr/bin/env ruby

require './boot'

# Start the main processing loop: listen to events from AWS KCL via STDIN
record_processor = KinesisToKafka::KinesisConsumer.new(KinesisToKafka::KafkaProducer.new)
driver = Aws::KCLrb::KCLProcess.new(record_processor)
driver.run
