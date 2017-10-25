require 'spec_helper'

describe 'f5' do
  it { is_expected.to compile.with_all_deps }
  it { is_expected.to contain_class('f5') }
  it do
    is_expected.to contain_package('faraday').with(
      'ensure'   => 'present',
      'provider' => 'puppet_gem'
    )
  end
end
