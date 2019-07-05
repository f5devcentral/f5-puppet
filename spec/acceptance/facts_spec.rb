require 'spec_helper_acceptance'

describe 'f5 facts' do
  before :all do
    pp=<<-EOS
      notify {
        "baseMac: ${baseMac}": ;
        "chassisId: ${chassisId}": ;
        "failoverState: ${failoverState}": ;
        "fullPath: ${fullPath}": ;
        "hostname: ${hostname}": ;
        "managementIp: ${managementIp}": ;
        "marketingName: ${marketingName}": ;
        "partition: ${partition}": ;
        "platformId: ${platformId}": ;
        "timeZone: ${timeZone}": ;
        "version: ${version}": ;
      }
    EOS
    make_site_pp(pp)
    @result = on(default, puppet('device', '--debug', '--color', 'false', '--user', 'root', '--trace', '--server', master.to_s))
  end
  it { expect(@result.stdout).to match /\[baseMac: ([0-9a-f][0-9a-f]:){5}[0-9a-f][0-9a-f]\]/ }
  it { expect(@result.stdout).to match /\[chassisId: [-0-9a-f]{31}\]/ }
  it { expect(@result.stdout).to match /\[failoverState: (active|standby)\]/ }
  it { expect(@result.stdout).to match /\[fullPath: ([-.a-z0-9\/]+)\]/i }
  it { expect(@result.stdout).to match /\[hostname: ([-.a-z0-9]+)\]/ }
  it { expect(@result.stdout).to match /\[managementIp: (\d+\.?){4}\]/ }
  it { expect(@result.stdout).to match /\[marketingName: BIG-IP Virtual Edition\]/ }
  it { expect(@result.stdout).to match /\[partition: Common\]/ }
  it { expect(@result.stdout).to match /\[platformId: Z100\]/ }
  it { expect(@result.stdout).to match /\[timeZone: (PDT|PST)\]/ }
  it { expect(@result.stdout).to match /\[version: 11.6.0\]/ }
end
