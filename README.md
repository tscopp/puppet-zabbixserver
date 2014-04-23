puppet-zabbixserver
===================

Once upon a time
-------------------

I needed a good module to install zabbix server's repeatedly and consistently. I could not find one so I wrote one. 

Usage
-------------------
After installing the module (either from here or the puppet forge) simply add the following to the desired node definition:

```
class {zabbixserver:
  db_host         => 'localhost
  db_port         => '0'
  db_name         => 'zabbix'
  db_password     => 'changeme'
  zabbix_host     => 'zabbix.school.edu'
  node_type       => 'server'
  zabbix_port     => '10051'
  zabbix_node_num => '0'
}
```

Problems?
-------------------
Submit a bug on here or contact me directly at tms@eecs.berkeley.edu.
