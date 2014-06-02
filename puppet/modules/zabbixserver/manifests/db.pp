class zabbixserver::db($db_name='zabbix',
                        $db_user='zabbix',
                        $db_password='changeme',
                        $db_root_password='strongpassword',
                        $db_host='localhost'){
  class{'mysql::server':
    root_password => $db_root_password,
  }
  mysql::db{ $db_name :
    user     => $db_user,
    password => $db_password,
    host     => $db_host,
    grant    => ['all'],
  }
  exec{'expand_zabbix_sql':
    command => 'gunzip /usr/share/zabbix-server-mysql/*',
    path    => '/bin/',
    creates => ['/usr/share/zabbix-server-mysql/data.sql',
                '/usr/share/zabbix-server-mysql/schema.sql',
                '/usr/share/zabbix-server-mysql/images.sql'],
  }
}
/*
exec{'insert_schema':
      command => "mysql -u root ${db_name} --password=${db_root_password} < /usr/share/zabbix-server-mysql/schema.sql",
      path    => '/usr/bin/',
      creates => '/tmp/schema.sql',
      require => [Exec['expand_zabbix_sql'],
                  Class['mysql::server'],]
    }
  }
    exec{'insert_images':
      command => "cp /usr/share/zabbix-server-mysql/images.sql /tmp && mysql -u ${db_user} --password=${db_password} ${db_name} < /tmp/images.sql",
      path    => '/bin/',
      creates => '/tmp/images.sql',
      require => Exec['expand_zabbix_sql']
    }
    exec{'insert_data':
      command => "cp /usr/share/zabbix-server-mysql/data.sql /tmp && mysql -u ${db_user} --password=${db_password} ${db_name} < /tmp/data.sql",
      path    => '/bin/',
      creates => '/tmp/data.sql',
      require => Exec['expand_zabbix_sql']
    }
*/
