require 'spec_helper'
describe 'f5' do

  context 'with defaults for all parameters' do
    it { should contain_class('f5') }
  end
end
