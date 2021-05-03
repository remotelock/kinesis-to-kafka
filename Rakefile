require 'open-uri'

ROOT_DIR = Pathname.new(File.expand_path '..', __FILE__)
JAR_DIR = ROOT_DIR.join('vendor', 'jars')
JAVA_HOME = ENV.fetch('JAVA_HOME') do
  raise 'JAVA_HOME environment variable not set.'
end

def get_maven_jar_info(group_id, artifact_id, version)
  jar_name = "#{artifact_id}-#{version}.jar"
  jar_url = "https://repo1.maven.org/maven2/#{group_id.tr('.', '/')}/#{artifact_id}/#{version}/#{jar_name}"
  local_jar_file = File.join(JAR_DIR, jar_name)
  [jar_name, jar_url, local_jar_file]
end

def download_maven_jar(group_id, artifact_id, version)
  _jar_name, jar_url, local_jar_file = get_maven_jar_info(group_id, artifact_id, version)
  URI.open(jar_url) do |remote_jar|
    URI.open(local_jar_file, 'w') do |local_jar|
      IO.copy_stream(remote_jar, local_jar)
    end
  end
end

MAVEN_PACKAGES = [
  # (group id, artifact id, version),
  ['software.amazon.kinesis', 'amazon-kinesis-client-multilang', '2.1.2'],
  ['software.amazon.kinesis', 'amazon-kinesis-client', '2.1.2'],
  ['software.amazon.awssdk', 'kinesis', '2.4.0'],
  ['software.amazon.awssdk', 'aws-cbor-protocol', '2.4.0'],
  ['com.fasterxml.jackson.dataformat', 'jackson-dataformat-cbor', '2.9.8'],
  ['software.amazon.awssdk', 'aws-json-protocol', '2.4.0'],
  ['software.amazon.awssdk', 'dynamodb', '2.4.0'],
  ['software.amazon.awssdk', 'cloudwatch', '2.4.0'],
  ['software.amazon.awssdk', 'netty-nio-client', '2.4.0'],
  ['io.netty', 'netty-codec-http', '4.1.32.Final'],
  ['io.netty', 'netty-codec-http2', '4.1.32.Final'],
  ['io.netty', 'netty-codec', '4.1.32.Final'],
  ['io.netty', 'netty-transport', '4.1.32.Final'],
  ['io.netty', 'netty-resolver', '4.1.32.Final'],
  ['io.netty', 'netty-common', '4.1.32.Final'],
  ['io.netty', 'netty-buffer', '4.1.32.Final'],
  ['io.netty', 'netty-handler', '4.1.32.Final'],
  ['io.netty', 'netty-transport-native-epoll', '4.1.32.Final'],
  ['io.netty', 'netty-transport-native-unix-common', '4.1.32.Final'],
  ['com.typesafe.netty', 'netty-reactive-streams-http', '2.0.0'],
  ['com.typesafe.netty', 'netty-reactive-streams', '2.0.0'],
  ['org.reactivestreams', 'reactive-streams', '1.0.2'],
  ['com.google.guava', 'guava', '26.0-jre'],
  ['com.google.code.findbugs', 'jsr305', '3.0.2'],
  ['org.checkerframework', 'checker-qual', '2.5.2'],
  ['com.google.errorprone', 'error_prone_annotations', '2.1.3'],
  ['com.google.j2objc', 'j2objc-annotations', '1.1'],
  ['org.codehaus.mojo', 'animal-sniffer-annotations', '1.14'],
  ['com.google.protobuf', 'protobuf-java', '2.6.1'],
  ['org.apache.commons', 'commons-lang3', '3.8.1'],
  ['org.slf4j', 'slf4j-api', '1.7.25'],
  ['io.reactivex.rxjava2', 'rxjava', '2.1.14'],
  ['software.amazon.awssdk', 'sts', '2.4.0'],
  ['software.amazon.awssdk', 'aws-query-protocol', '2.4.0'],
  ['software.amazon.awssdk', 'protocol-core', '2.4.0'],
  ['software.amazon.awssdk', 'profiles', '2.4.0'],
  ['software.amazon.awssdk', 'sdk-core', '2.4.0'],
  ['com.fasterxml.jackson.core', 'jackson-core', '2.9.8'],
  ['com.fasterxml.jackson.core', 'jackson-databind', '2.9.8'],
  ['software.amazon.awssdk', 'auth', '2.4.0'],
  ['software.amazon', 'flow', '1.7'],
  ['software.amazon.awssdk', 'http-client-spi', '2.4.0'],
  ['software.amazon.awssdk', 'regions', '2.4.0'],
  ['com.fasterxml.jackson.core', 'jackson-annotations', '2.9.0'],
  ['software.amazon.awssdk', 'annotations', '2.4.0'],
  ['software.amazon.awssdk', 'utils', '2.4.0'],
  ['software.amazon.awssdk', 'aws-core', '2.4.0'],
  ['software.amazon.awssdk', 'apache-client', '2.4.0'],
  ['org.apache.httpcomponents', 'httpclient', '4.5.6'],
  ['commons-codec', 'commons-codec', '1.10'],
  ['org.apache.httpcomponents', 'httpcore', '4.4.10'],
  ['com.amazonaws', 'aws-java-sdk-core', '1.11.477'],
  ['commons-logging', 'commons-logging', '1.1.3'],
  ['software.amazon.ion', 'ion-java', '1.0.2'],
  ['joda-time', 'joda-time', '2.8.1'],
  ['ch.qos.logback', 'logback-classic', '1.2.3'],
  ['ch.qos.logback', 'logback-core', '1.2.3'],
  ['com.beust', 'jcommander', '1.72'],
  ['commons-io', 'commons-io', '2.6'],
  ['org.apache.commons', 'commons-collections4', '4.2'],
  ['commons-beanutils', 'commons-beanutils', '1.9.3'],
  ['commons-collections', 'commons-collections', '3.2.2']
].freeze

namespace :kinesis_to_kafka do
  task download_jars: [JAR_DIR]

  MAVEN_PACKAGES.each do |jar|
    _, _, local_jar_file = get_maven_jar_info(*jar)
    file local_jar_file do
      puts "Downloading Kinesis dependency from Maven: '#{local_jar_file}'"
      download_maven_jar(*jar)
    end
    task download_jars: local_jar_file
  end

  desc 'Run consumer that reads from Kinesis and publishes to Kafka'
  task run: %i[download_jars] do
    require './boot'

    properties_file = KinesisToKafka::KinesisProperties.generate_file
    stream_executable_dir = KinesisToKafka.root.join('bin')

    log_configuration = ENV['AWS_KINESIS_LOG_CONFIGURATION']
    classpath = FileList["#{JAR_DIR}/*.jar"].join(':')
    classpath += ":#{stream_executable_dir}"
    ENV['PATH'] = "#{ENV['PATH']}:#{stream_executable_dir}"

    command = [
      "#{JAVA_HOME}/bin/java",
      "-classpath #{classpath}",
      'software.amazon.kinesis.multilang.MultiLangDaemon',
      "--properties-file #{properties_file}"
    ]
    command << "--log-configuration #{log_configuration}" if log_configuration

    puts 'Running the Kinesis Stream consumer application...'
    sh command.join(' ')
  end
end
