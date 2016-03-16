# encoding: utf-8

require 'spec_helper'

describe 'kkafka::default' do
  let :chef_run do
    ChefSpec::Runner.new.converge(described_recipe)
  end

  it 'includes kkafka::_defaults' do
    expect(chef_run).to include_recipe('kkafka::_defaults')
  end

  it 'includes kkafka::_setup' do
    expect(chef_run).to include_recipe('kkafka::_setup')
  end

  it 'includes kkafka::_install recipe' do
    expect(chef_run).to include_recipe('kkafka::_install')
  end

  it 'includes kkafka::_configure' do
    expect(chef_run).to include_recipe('kkafka::_configure')
  end
end
