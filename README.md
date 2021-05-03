# kinesis-to-kafka

# Running

```
export $(cat .env | xargs) && bundle exec rake kinesis_to_kafka:run
```

### Manual Test:

**Consuming:**
```
$ docker exec -it kafka-broker bash

...@b729d001f451:/$ kafka-console-consumer.sh --bootstrap-server localhost:9092 --topic kafka_events --from-beginning
```

**Producing:**

```
export AWS_KINESIS_REGION=us-east-1
export AWS_KINESIS_STREAM_NAME=kinesis_events
export AWS_KINESIS_ACCESS_KEY_ID=
export AWS_KINESIS_SECRET_ACCESS_KEY=

gem install aws-sdk-kinesis

ruby -r aws-sdk-kinesis -e "
  client = Aws::Kinesis::Client.new(
    region: ENV.fetch('AWS_KINESIS_REGION'),
    access_key_id: ENV.fetch('AWS_KINESIS_ACCESS_KEY_ID'),
    secret_access_key: ENV.fetch('AWS_KINESIS_SECRET_ACCESS_KEY'),
  )
  client.put_record(
    stream_name: ENV.fetch('AWS_KINESIS_STREAM_NAME'),
    data: JSON.dump({ id: SecureRandom.uuid }),
    partition_key: 'key',
  )
"
```
