# Private class
class f5::install {
  $provider = $::puppetversion ? {
    /Puppet Enterprise/ => 'pe_gem',
    default             => 'gem',
  }
  package { 'faraday':
    ensure   => present,
    provider => $provider,
  }
}
