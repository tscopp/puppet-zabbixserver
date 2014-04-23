class zabbixserver::apt(){
  apt::source { 'zabbx_repo':
    location   => 'http://ppa.launchpad.net/tbfr/zabbix/ubuntu',
    release    => 'precise',
    repos      => 'main',
    key        => 'C407E17D5F76A32B',
    key_server => 'keyserver.ubuntu.com',
    before     => Exec['apt-update'],
  }

  exec { 'apt-update':
    command => '/usr/bin/apt-get update',
  }

}
