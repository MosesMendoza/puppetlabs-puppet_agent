class puppet_agent::osfamily::redhat {
  if $::operatingsystem == 'Fedora' {
    $urlbit = 'fedora/f$releasever'
  }
  else {
    $urlbit = 'el/$releasever'
  }

  $keyname = 'RPM-GPG-KEY-puppetlabs'
  $gpg_path = "/etc/pki/rpm-gpg/${keyname}"

  file { ['/etc/pki', '/etc/pki/rpm-gpg']:
    ensure => directory,
  }

  file { $gpg_path:
    ensure => present,
    owner  => 0,
    group  => 0,
    mode   => '0644',
    source => "puppet:///modules/puppet_agent/${keyname}",
  }

  # Given the path to a key, see if it is imported, if not, import it
  exec {  "import-${keyname}":
    path      => '/bin:/usr/bin:/sbin:/usr/sbin',
    command   => "rpm --import ${gpg_path}",
    unless    => "rpm -q gpg-pubkey-`echo $(gpg --throw-keyids < ${gpg_path}) | cut --characters=11-18 | tr [A-Z] [a-z]`",
    require   => File[$gpg_path],
    logoutput => 'on_failure',
  }

  yumrepo { 'pe_repo':
    baseurl  => "https://vqt4g854yitgoc5.delivery.puppetlabs.net:8140/packages/3.8.0/el-7-x86_64",
    descr    => "PE REPO",
    enabled  => true,
    gpgcheck => '1',
    sslverify => false,
    gpgkey   => "file://$gpg_path",
  }
}

