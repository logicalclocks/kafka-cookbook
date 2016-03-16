# encoding: utf-8

require 'spec_helper'

describe 'kkafka::_install' do
  let :chef_run do
    r = ChefSpec::Runner.new(step_into: %w(kkafka_download kkafka_install))
    r.converge(*described_recipes)
  end

  let :described_recipes do
    ['kkafka::_defaults', described_recipe]
  end

  it 'downloads remote binary release of Kafka' do
    expect(chef_run).to create_kafka_download(%(#{Chef::Config.file_cache_path}/kafka_2.9.2-0.8.1.1.tgz))
    expect(chef_run).to create_remote_file(%(#{Chef::Config.file_cache_path}/kafka_2.9.2-0.8.1.1.tgz))
  end

  it 'validates download' do
    expect(chef_run).not_to run_ruby_block('kkafka-validate-download')

    remote_file = chef_run.remote_file(%(#{Chef::Config.file_cache_path}/kafka_2.9.2-0.8.1.1.tgz))
    expect(remote_file).to notify('ruby_block[kkafka-validate-download]').immediately
  end

  it 'extracts downloaded Kafka archive' do
    expect(chef_run).to run_execute('extract-kkafka').with({
      cwd: %(#{Dir.tmpdir}/kkafka-build),
    })
  end

  it 'installs extracted Kafka archive' do
    expect(chef_run).to run_kafka_install('/opt/kafka-0.8.1.1')
    expect(chef_run).to run_execute('install-kkafka')
    expect(chef_run).to run_execute('remove-kkafka-build')
    link = chef_run.link('/opt/kafka')
    expect(link).to link_to('/opt/kafka-0.8.1.1')
  end

  context 'archive extension for different versions' do
    let :chef_run do
      ChefSpec::Runner.new do |node|
        node.set[:kkafka][:version] = kkafka_version
        node.set[:kkafka][:install_method] = :binary
      end.converge(*described_recipes)
    end

    context 'when version is 0.8.0' do
      let :kkafka_version do
        '0.8.0'
      end

      it 'uses .tar.gz' do
        expect(chef_run).to create_kkafka_download(%(#{Chef::Config.file_cache_path}/kafka_2.9.2-0.8.0.tar.gz))
      end

      it 'installs kafka' do
        expect(chef_run).to run_kafka_install('/opt/kafka-0.8.0')
      end
    end

    context 'when version is 0.8.1' do
      let :kkafka_version do
        '0.8.1'
      end

      it 'uses .tgz' do
        expect(chef_run).to create_kafka_download(%(#{Chef::Config.file_cache_path}/kafka_2.9.2-0.8.1.tgz))
      end

      it 'installs kafka' do
        expect(chef_run).to run_kafka_install('/opt/kafka-0.8.1')
      end
    end

    context 'when version is 0.8.1.1' do
      let :kkafka_version do
        '0.8.1.1'
      end

      it 'uses .tgz' do
        expect(chef_run).to create_kafka_download(%(#{Chef::Config.file_cache_path}/kafka_2.9.2-0.8.1.1.tgz))
      end

      it 'installs kafka' do
        expect(chef_run).to run_kafka_install('/opt/kafka-0.8.1.1')
      end
    end
  end
end
