class f5 {
  package { 'faraday':
    ensure   => present,
    provider => 'puppet_gem',
  }
}
