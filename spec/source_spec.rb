# encoding: utf-8

require 'spec_helper'

describe 'kafka::source' do
  let :chef_run do
    ChefSpec::Runner.new(platform: 'centos', version: '6.4').converge(described_recipe)
  end

  let :remote_file do
    chef_run.remote_file("#{Chef::Config[:file_cache_path]}/kafka-0.8.0-beta1-src.tgz")
  end

  it 'includes kafka::default recipe' do
    expect(chef_run).to include_recipe('kafka::default')
  end

  it 'creates build directory' do
    expect(chef_run).to create_directory('/opt/kafka/build')

    directory = chef_run.directory('/opt/kafka/build')
    expect(directory.owner).to eq('kafka')
    expect(directory.group).to eq('kafka')
    expect(directory.mode).to eq('755')
  end

  it 'downloads remote source of Kafka' do
    expect(chef_run).to create_remote_file("#{Chef::Config[:file_cache_path]}/kafka-0.8.0-beta1-src.tgz").with(
      source:   'https://dist.apache.org/repos/dist/release/kafka/kafka-0.8.0-beta1-src.tgz',
      checksum: 'e069a1d5e47d18944376b6ca30b625dc013045e7e1f948054ef3789a4b5f54b3',
      mode: '644'
    )
  end

  it 'compiles Kafka source' do
    expect(remote_file).to notify('execute[compile-kafka]').to(:run).immediately

    compile_kafka = chef_run.execute('compile-kafka')
    expect(compile_kafka.cwd).to eq('/opt/kafka/build')
    expect(compile_kafka.user).to be_nil
    expect(compile_kafka.group).to be_nil
  end

  it 'installs compiled Kafka source' do
    expect(chef_run.execute('compile-kafka')).to notify('execute[install-kafka]').to(:run).immediately

    install_kafka = chef_run.execute('install-kafka')
    expect(install_kafka.cwd).to eq('/opt/kafka')
    expect(install_kafka.user).to eq('kafka')
    expect(install_kafka.group).to eq('kafka')
  end
end