require 'erb'

module KinesisToKafka
  module KinesisProperties
    TEMPLATE_FILE = KinesisToKafka.root.join('config', 'kinesis_consumer.properties.erb').to_s
    OUTPUT_FILE = KinesisToKafka.root.join('tmp', 'kinesis_consumer.properties').to_s

    def self.generate_file
      erb = ERB.new(File.read(TEMPLATE_FILE))
      erb.filename = TEMPLATE_FILE
      generated_properties = erb.result

      File.write(OUTPUT_FILE, generated_properties)
      OUTPUT_FILE
    end
  end
end
