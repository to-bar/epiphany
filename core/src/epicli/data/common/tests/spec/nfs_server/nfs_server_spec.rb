require 'spec_helper'

nfs_exports = readDataYaml("configuration/nfs-server")["specification"]["nfs_exports"]
nfs_default_port = 2049

if os[:family] == 'redhat'
  describe 'Checking if NFS service is running' do
    describe service('nfs') do
      it { should be_enabled }
      it { should be_running }
    end
  end
elsif os[:family] == 'ubuntu'
  describe 'Checking if NFS service is running' do
    describe service('nfs-kernel-server') do
      it { should be_enabled }
      it { should be_running }
    end
  end
end

describe 'Checking if NFS port is open' do
  let(:disable_sudo) { false }
  describe port(nfs_default_port) do
    it { should be_listening }
  end
end

describe 'Checking configuration file for NFS exports' do
  describe file('/etc/exports') do
    it { should exist }
    it { should be_a_file }
  end
end

describe 'Checking available NFS mounts' do
  let(:disable_sudo) { false }
  nfs_exports.select {|i|
    describe command("showmount -e localhost | grep #{i['export_directory'].chomp('/')}") do
      its(:stdout) { should match /^#{i["export_directory"].chomp("/")}*/}
      its(:exit_status) { should eq 0 }
    end}
end
