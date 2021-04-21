require 'spec_helper'

describe 'postgresql::postgresql_password' do
  it_behaves_like 'postgresql_password function'
end
