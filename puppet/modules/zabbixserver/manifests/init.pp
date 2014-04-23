# == Class: zabbixserver
#
# Zabbixserver attempts to install and (minimally) configure a zabbix server
#
# === Parameters
#
# Document parameters here.
#
#  class { zabbixserver:
#    db_host         => 'localhost'
#    db_port         => '0'
#    db_name         => 'zabbix'
#    db_password     => 'changeme'
#    zabbix_host     => $fqdn
#    node_type       => 'server'
#    zabbix_port     => '10051'
#    zabbix_node_num => '0'
#  }
#
# === Authors
#
# Author Name <tms@eecs.berkeley.edu>
#
# === Copyright
#
# Copyright 2013 Tim Scoppetta, unless otherwise noted.
#

class zabbixserver(
  $db_host         = 'localhost',
  $db_port         = '0',
  $db_name         = 'zabbix',
  $db_user         = 'zabbix',
  $db_password     = 'changeme',
  $zabbix_host     = $::fqdn,
  $node_type       = 'server',
  $zabbix_port     = '10051',
  $zabbix_node_num = '1',
){

  # Add the necessary repo and update apt
  #class{'zabbixserver::apt': }
  apt::source { 'zabbx_repo':
    location   => 'http://ppa.launchpad.net/tbfr/zabbix/ubuntu',
    release    => 'precise',
    repos      => 'main',
    key        => 'C407E17D5F76A32B',
    key_server => 'keyserver.ubuntu.com',
    before     => Exec['apt-update'],
  }
  exec { "apt-update":
      command => "/usr/bin/apt-get update"
  }
  Exec["apt-update"] -> Package <| |>

  # install the package for the desired node type
  if $node_type == 'node'{
    package{'zabbix-server-mysql':
      ensure  => installed,
    }
  } elsif $node_type == 'proxy' {
    package{'zabbix-proxy-sqlite3':
      ensure  => installed,
    }
  } else {
    package{['zabbix-server-mysql','zabbix-frontend-php']:
      ensure  => 'installed',
    }
  }

  if $node_type != 'proxy' {
    class{'mysql::server':}
    mysql::db{ $db_name :
      user     => $db_user,
      password => $db_password,
      host     => $db_host,
      grant    => ['all'],
      before   => [Exec['insert_schema'],
                    Exec['insert_images'],
                    Exec['insert_data'],]
    }
    exec{'expand_zabbix_sql':
      command => 'gunzip /usr/share/zabbix-server-mysql/*.gz',
      path    => '/bin/',
      require => Package['zabbix-server-mysql'],
      creates => ['/usr/share/zabbix-server-mysql/data.sql',
                '/usr/share/zabbix-server-mysql/schema.sql',
                '/usr/share/zabbix-server-mysql/images.sql'],
    }
  }

  exec{'insert_schema':
    command => "mysql -u root ${db_name} < /usr/share/zabbix-server-mysql/schema.sql",
    path    => '/usr/bin/',
    unless  => 'test 104 -eq $(mysql -u root -e \'SHOW TABLES\' zabbix | wc -l)',
    before  => [Exec['insert_images'],
                Exec['insert_data']],
  }

  exec{'insert_images':
    command => "mysql -u root ${db_name} < /usr/share/zabbix-server-mysql/images.sql",
    path    => '/usr/bin/',
    unless  => 'test 188 -eq $(mysql -u root -e \'SELECT * FROM images\' zabbix | wc -l)',
    require => Exec['expand_zabbix_sql'],
  }
  exec{'insert_data':
    command => "mysql -u root ${db_name} < /usr/share/zabbix-server-mysql/data.sql",
    path    => '/usr/bin/',
    unless  => 'test 2 -eq $(mysql -u root -e \'SELECT * FROM config\' zabbix | wc -l)',
    require => Exec['expand_zabbix_sql'],
  }

  file{'zabbix-server':
    ensure  => file,
    path    => '/etc/default/zabbix-server',
    content => template('zabbixserver/zabbix-server.erb'),
  }
  file{'zabbix_server.conf':
    ensure  => file,
    path    => '/etc/zabbix/zabbix_server.conf',
    content => template('zabbixserver/zabbix_server.conf.erb'),
    require => Package['zabbix-server-mysql'],
  }
  service{'zabbix-server':
    ensure  => 'running',
    enable => true,
  }

  if $node_type == 'server' {
    #php::ini { '/etc/php5/apache2/php.ini':
    #  post_max_size      => '16M',
    #  max_execution_time => '300',
    #  max_input_time     => '300',
    #  date_timezone      => 'UTC',
    #}
    class {'apache':
      service_enable => true
    }
    apache::mod {'rewrite':}
    apache::mod {'php5':}
    apache::vhost { $zabbix_host:
      port          => ['80'],
      docroot       => '/var/www',
      rewrite_cond  => '%{SERVER_PORT} 80',
      rewrite_rule  => "^(.*)$ https://${zabbix_host}/$1 [R=301,L]"
    }
    apache::vhost { "ssl.${zabbix_host}":
      port     => ['443'],
      docroot  => '/usr/share/zabbix',
      ssl      => true,
    }
    file{'zabbix.conf.php':
      ensure  => file,
      path    => '/etc/zabbix/zabbix.conf.php',
      require => Package['zabbix-server-mysql', 'apache2'],
      content => template('zabbixserver/zabbix.conf.php.erb'),
    }

    exec{'create_node':
      command => "zabbix_server -n ${zabbix_node_num} && echo ${zabbix_node_num} > /root/.zabbix_node",
      path    => '/usr/sbin/',
      creates => '/root/.zabbix_node',
      require => [Service['zabbix-server'],
                  Exec['insert_schema'],
                  Exec['insert_images'],
                  Exec['insert_data']],
    }
  }
}


