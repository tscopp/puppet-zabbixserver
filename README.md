puppet-zabbixserver
===================

Once upon a time
-------------------

I needed a good module to install zabbix server's repeatedly and consistently. I could not find one so I wrote one. 

Usage
-------------------
After installing the module (either from here or the puppet forge) simply add the following to the desired node definition:
<br /> <br />
class {zabbixserver: <br />
  db_host         => 'localhost <br />
  db_port         => '0' <br />
  db_name         => 'zabbix' <br />
  db_password     => 'changeme' <br />
  zabbix_host     => 'zabbix.school.edu' <br />
  node_type       => 'server' <br />
  zabbix_port     => '10051' <br />
  zabbix_node_num => '0'<br />
}<br /> <br />

Problems?
-------------------
Submit a bug on here or contact me directly at tms@eecs.berkeley.edu.
