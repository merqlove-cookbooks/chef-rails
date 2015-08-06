require 'spec_helper'

describe 'rails::default' do
  # Serverspec examples can be found at
  # http://serverspec.org/resource_types.html
  describe command('psql --version') do
    its(:stdout) { should match /psql \(PostgreSQL\) 9\.4/ }
  end

  describe port(5432) do
    it { should be_listening }
  end
end
