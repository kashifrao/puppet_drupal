
class project::cms_main(  
 
)
  
   {


# ----------------------------------------------------------------------------
# initiating apache server

 class { 'apache':
    
  }
  

# setting apache vhost configuration
$servername = "example.com"
$override   = "All"

apache::vhost { $servername:
      servername      => $servername,
      port            => '80',
      docroot         => '/var/www/html/',
      access_log_file => "${servername}_access.log",
      error_log_file  => "${servername}_error.log",
      
      directories => [
        {
            path => '/var/www/html',
            options => 'Indexes FollowSymLinks MultiViews',
            allow_override => $override,
        },
    ],
    }
    

#setting it for drupal to work 
   file_line { "default_conf_allow_override":
                path => "/etc/httpd/conf.d/15-default.conf",
                ensure => present,
                line => "AllowOverride All",
                match => "AllowOverride.*$",
                notify => Service["httpd"],
        } 
    
    
    
   
# ----------------------------------------------------------------------------
# mysql server setup
# ----------------------------------------------------------------------------

#allow mysql to listen every ip address  
   $override_options = {
  'mysqldump' => {
    'password'=> [hiera('bundle::project::mysql_main::backup_pass')],
  },
  
   'mysqld' => {
    'bind-address' => [''],
  }

}

 
#initiating mysql server
  class { '::mysql::server':
  root_password           => hiera('project::mysql_main::root_pass'),
  remove_default_accounts => true,
  override_options        => $override_options
}

  # create general mysql user for backups, phpmyadmin and other
mysql::db { 'mysql':
  user     => 'master',
  password => hiera('project::mysql_main::master_pass'),
  host     => '%',
  grant    => ['SELECT', 'INSERT', 'UPDATE', 'DELETE'],
}

# ----------------------------------------------------------------------------
#mysql user creation and restoring mysql dump from /srv/shared
#create dctcms database and user

mysql::db { 'db_cms':
  user     => 'dbcms',
  password => hiera('project::mysql_main::db_pass'),
  host     => '%',
  grant    => ['SELECT', 'INSERT', 'UPDATE', 'DELETE'],
}

   
# assign privileges to master
mysql_grant { 'dbcms@%/*.*':
  ensure     => 'present',
  options    => ['GRANT'],
  privileges => ['ALL'],
   table      => '*.*',
  user       => 'ncicms@%',
}

  
 
#  ----------------------------------------------------------------------------
# download drupal source code  
 
      
      untar { "/NCIDrupal" : 
      source => "https://ftp.drupal.org/files/projects/drupal-7.50.tar.gz",
      }
      
# copy application code from /NCI Drupal folder to main folder
    file { "/var/www/html":
      ensure => "directory",
      source => "/Drupal",
      recurse => "true",
      owner => "xxxxxxx",
       group => "xxxxxx",
      mode    => '0775',
      }


   
# ----------------------------------------------------------------------------
# Add any additional settings *above* this comment block.
# ----------------------------------------------------------------------------

   
}
