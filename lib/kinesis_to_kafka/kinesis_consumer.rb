require 'json'
require 'base64'

module KinesisToKafka
  class KinesisConsumer < Aws::KCLrb::V2::RecordProcessorBase
    CHECKPOINT_FREQUENCY = 10 # seconds

    def initialize(data_processor)
      self.data_processor = data_processor
    end

    # (see Aws::KCLrb::V2::RecordProcessorBase#init_processor)
    def init_processor(initialize_input)
      self.shard_id = initialize_input.shard_id
      self.last_checkpoint_time = Time.now - CHECKPOINT_FREQUENCY
      LOGGER.info 'Started'
    end

    # (see Aws::KCLrb::V2::RecordProcessorBase#process_records)
    def process_records(process_records_input)
      records = process_records_input.records
      last_sequence = records.last.fetch('sequenceNumber')

      data_processor.handle_records(
        records.map { |record|
          {
            data: record.fetch('data'),
            partition_key: record.fetch('partitionKey'),
            approximate_arrival_timestamp: record.fetch('approximateArrivalTimestamp'),
            sequence_number: record.fetch('sequenceNumber'),
            subsequence_number: record.fetch('subSequenceNumber'),
          }
        }
      )

      return if last_sequence.nil? # No record was processed, do not write checkpoint
      return if (Time.now - last_checkpoint_time) <= CHECKPOINT_FREQUENCY

      checkpoint_helper(process_records_input.checkpointer, last_sequence)
      self.last_checkpoint_time = Time.now
      LOGGER.info "Checkpoint at sequence #{last_sequence}"
    end

    # (see Aws::KCLrb::V2::RecordProcessorBase#lease_lost)
    def lease_lost(lease_lost_input)
      # Lease was stolen by another Worker.
      LOGGER.warn 'Lease lost - stolen by another worker'
    end

    # (see Aws::KCLrb::V2::RecordProcessorBase#shard_ended)
    def shard_ended(shard_ended_input)
      LOGGER.warn 'Shard ended'
      checkpoint_helper(shard_ended_input.checkpointer)
    end

    # (see Aws::KCLrb::V2::RecordProcessorBase#shutdown_requested)
    def shutdown_requested(shutdown_requested_input)
      LOGGER.info 'Shutdown requested'
      checkpoint_helper(shutdown_requested_input.checkpointer)
    end

    private

    attr_accessor :data_processor, :last_checkpoint_time, :shard_id

    # Helper method that retries checkpointing once.
    # @param checkpointer [Aws::KCLrb::Checkpointer] The checkpointer instance to use.
    # @param sequence_number (see Aws::KCLrb::Checkpointer#checkpoint)
    def checkpoint_helper(checkpointer, sequence_number = nil)
      begin
        checkpointer.checkpoint(sequence_number)
      rescue Aws::KCLrb::CheckpointError
        Retriable.with_context(:kinesis_stream_checkpoint) do
          checkpointer.checkpoint(sequence_number) if sequence_number
        end
      end
    end
  end
end
