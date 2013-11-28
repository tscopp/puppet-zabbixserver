# ZabbixServer
# Builds a zabbix server from scratch and configures all
# intial values to sane defaults.
#
# Author: tms@eecs.berkeley.edu
# Date: 07/08/2013
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
  $zabbix_node_num = '0',
){
  apt::source { 'zabbx_repo':
    location   => 'http://ppa.launchpad.net/tbfr/zabbix/ubuntu',
    release    => 'precise',
    repos      => 'main',
    key        => 'C407E17D5F76A32B',
    key_server => 'keyserver.ubuntu.com',
    before     => Exec['apt-update'],
  }
  exec{'apt-update':
    command   => 'apt-get update',
    path      => '/usr/bin',
  }
  file{'zabbix_server.conf':
    ensure  => file,
    path    => '/etc/zabbix/zabbix_server.conf',
    require => Package['zabbix-server-mysql'],
    content => template('zabbixserver/zabbix_server.conf.erb'),
  }
  file{'zabbix-server':
    ensure  => file,
    path    => '/etc/default/zabbix-server',
    content => template('zabbixserver/zabbix-server.erb'),
  }
  service{'zabbix-server':
    ensure  => 'running',
    enable => true,

  }
  if $node_type == 'node'{
    package{'zabbix-server-mysql':
      ensure  => installed,
      require => Exec['apt-update'],
    }
  } elsif $node_type == 'proxy' {
    package{'zabbix-proxy-sqlite3':
      ensure  => installed,
      require => Exec['apt-update'],
    }
  } else {
    package{['zabbix-server-mysql','zabbix-frontend-php']:
      ensure  => 'installed',
      require => Exec['apt-update'],
    }
  }

  if $node_type != 'proxy' {
    # Create and populate the databases
    if $db_host == 'localhost' {
      class{'mysql': }
      class{'mysql::server': }
    }
    mysql::db{ $db_name :
      user     => $db_user,
      password => $db_password,
      host     => $db_host,
      grant    => ['all'],
    }
    exec{'expand_zabbix_sql':
      command => 'gunzip /usr/share/zabbix-server-mysql/*',
      creates => ['/usr/share/zabbix-server-mysql/data.sql',
                  '/usr/share/zabbix-server-mysql/schema.sql',
                  '/usr/share/zabbix-server-mysql/images.sql'],
    }
    exec{'insert_schema':
      command => "cp /usr/share/zabbix-server-mysql/schema.sql /tmp && mysql -u ${db_user} --password=${db_password} ${db_name} < /tmp/schema.sql",
      creates => '/tmp/schema.sql',
      require => Exec['expand_zabbix_sql']
    }
    exec{'insert_images':
      command => "cp /usr/share/zabbix-server-mysql/images.sql /tmp && mysql -u ${db_user} --password=${db_password} ${db_name} < /tmp/images.sql",
      creates => '/tmp/images.sql',
      require => Exec['expand_zabbix_sql']
    }
    exec{'insert_data':
      command => "cp /usr/share/zabbix-server-mysql/data.sql /tmp && mysql -u ${db_user} --password=${db_password} ${db_name} < /tmp/data.sql",
      creates => '/tmp/data.sql',
      require => Exec['expand_zabbix_sql']
    }
    if $node_type == 'server' {
      php::ini { '/etc/php5/apache2/php.ini':
        post_max_size      => '16M',
        max_execution_time => '300',
        max_input_time     => '300',
        date_timezone      => 'UTC',
      }
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
    } elsif $zabbix_node == true {
      exec{'create_node':
        command => "zabbix_server -n ${zabbix_node_num} && touch /root/.zabbix_node",
        creates => '/root/.zabbix_node',
        require => Service['zabbix-server'],
      }
    }
  }
}

