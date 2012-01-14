# Pseudo distributed Hbase install (using Cloudera distribution)
# (all daemons running in one machine)
#
# Parameters:
#   $java_installer = Oracle's java rpm.bin file, recommended by Cloudera
# Requires:
#   java installer downloaded and present
# 

# Parameter
$java_installer = '/vagrant/installers/jdk-6u21-linux-x64-rpm.bin' # this is the installer for the cloudera recommended java version, must to be present on this path

Exec {
	path => [
		'/usr/local/sbin',
		'/usr/sbin',
		'/sbin',
		'/usr/local/bin',
		'/bin',
		'/usr/bin',
		'/home/vagrant/bin'
	],
	logoutput => on_failure
}

# JAVA
file { 'java installer':
	path => $java_installer,
	ensure => present,
	mode => '711'
}

exec { 'java install':
	command => $java_installer,
	creates => '/usr/bin/java',
	require => File['java installer']
}

# CLOUDERA REPOSITORY

yumrepo { 'cloudera-cdh3':
	name => 'cloudera-cdh3.repo',
	mirrorlist => 'http://archive.cloudera.com/redhat/cdh/3/mirrors',
	gpgkey => 'http://archive.cloudera.com/redhat/cdh/RPM-GPG-KEY-cloudera',
	gpgcheck => 0,
	enabled => 1
}

#exec { 'gpm-cloudera':
#	command => 'rpm --import http://archive.cloudera.com/redhat/6/x86_64/cdh/RPM-GPG-KEY-cloudera',
#	require => Yumrepo['cloudera-cdh3']
#}

# HADOOP packages

package { 'hadoop-0.20':
	ensure => installed,
	require => [
		Exec['java install'],
    #		Exec['gpm-cloudera']
	]
}

package { 'hadoop-0.20-namenode':
	ensure => installed,
	require => Package['hadoop-0.20']
}

package { 'hadoop-0.20-datanode':
	ensure => installed,
	require => Package['hadoop-0.20']
}

package { 'hadoop-0.20-secondarynamenode':
	ensure => installed,
	require => Package['hadoop-0.20']
}

package { 'hadoop-0.20-jobtracker':
	ensure => installed,
	require => Package['hadoop-0.20']
}

package { 'hadoop-0.20-tasktracker':
	ensure => installed,
	require => Package['hadoop-0.20']
}

package { 'hadoop-0.20-conf-pseudo':
	ensure => installed,
	require => Package['hadoop-0.20']
}

# HADOOP services

Service {
	ensure => running,
	enable => true,
	hasstatus => true,
	hasrestart => true
}

service { 'hadoop-0.20-namenode':
	require => Package['hadoop-0.20-namenode']
}

service { 'hadoop-0.20-secondarynamenode':
	require => [
		Service['hadoop-0.20-namenode'],
		Package['hadoop-0.20-secondarynamenode']
	]
}

service { 'hadoop-0.20-datanode':
	require => [
		Service['hadoop-0.20-secondarynamenode'],
		Package['hadoop-0.20-datanode']
	]
}

service { 'hadoop-0.20-jobtracker':
	require => [
		Service['hadoop-0.20-datanode'],
		Package['hadoop-0.20-jobtracker']
	]
}

service { 'hadoop-0.20-tasktracker':
	require => [
		Service['hadoop-0.20-jobtracker'],
		Package['hadoop-0.20-tasktracker']
	]
}

# ZOOKEEPER packages

package { 'hadoop-zookeeper':
	ensure => installed,
	require => Package['hadoop-0.20']
}

package { 'hadoop-zookeeper-server':
	ensure => installed,
	require => Package['hadoop-zookeeper']
}

# HBASE packages

package { 'hadoop-hbase':
	ensure => installed,
	require => Package['hadoop-zookeeper-server']
}

package { 'hadoop-hbase-master':
	ensure => installed,
	require => Package['hadoop-hbase']
}

file { '/etc/hbase/conf/hbase-site.xml':
	content => "<?xml version=\"1.0\"?><?xml-stylesheet type=\"text/xsl\" href=\"configuration.xsl\"?>
		<configuration>
		 <property>
		   <name>hbase.cluster.distributed</name>
		   <value>true</value>
		 </property>
		 <property>
		   <name>hbase.rootdir</name>
		   <value>hdfs://localhost:8020/hbase</value>
		 </property>
		</configuration>",
	ensure => present,
	mode => '644',
	owner => 'root',
	group => 'root',
	require => Package['hadoop-hbase-master']
}

exec { 'hdfs-setup-hbase':
	command => 'sudo -u hdfs hadoop fs -mkdir /hbase && sudo -u hdfs hadoop fs -chown hbase /hbase',
	unless => 'sudo -u hdfs hadoop fs -ls /hbase',
	require => File['/etc/hbase/conf/hbase-site.xml']
}

package { 'hadoop-hbase-regionserver':
	ensure => installed,
	require => Package['hadoop-hbase-master']
}

# HBASE services

service { 'hadoop-zookeeper-server':
	require => [
		Service['hadoop-0.20-tasktracker'],
		Package['hadoop-zookeeper-server']
	]
}

service { 'hadoop-hbase-master':
	require => [
		Service['hadoop-zookeeper-server'],
		Package['hadoop-hbase-master']
	]
}

service { 'hadoop-hbase-regionserver':
	require => [
		Service['hadoop-hbase-master'],
		Package['hadoop-hbase-regionserver']
	]
}
