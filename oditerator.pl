#!/usr/bin/perl
# If you don't know the code, don't mess around below - BCIV
use Net::LDAP;
use Net::LDAP::Extension::SetPassword;

my $base; my $diradmin; my $password; my $system; 
my $url; 
my $helpdeskurl; my $helpdeskcontact; my $helpdeskemail;

`rm oditerator*.log`;

# step 1, iterate through LDAP to retrieve: 
#	username, shortusername, email address

# step 2, at each iteration set password

# step 3, send emails to notify users of new password

# step 4, probably time to turn off OD on the old server


my $stage='dev'; # dev, test, prod

# set environment variable based on deployment stage
#
if($stage eq 'prod'){
  $base="dc=servername,dc=example,dc=com"; 
  $diradmin='diradmin';
  $password='supersecretpassword12345!!!!';
  $system="Apple Wiki";
  $url="https://wiki.example.com";
  $helpdeskurl="http://help.example.com";
  $helpdeskemail="help@example.com";
  $helpdeskcontact="Help Desk Team";
}
elsif($stage eq 'dev'){
  $base="dc=MyComputerName,dc=local"; 
  $diradmin='diradmin';
  $password='supersecretpassword12345!!!!';
  $system="Development Server";
  $url="http://localhost";
  $helpdeskurl="http://help.MyComputer.local";
  $helpdeskemail="test1\@example.com";
  $helpdeskcontact="Test Help Contact";
}

#my $attrs=['FirstName','cn','RecordName','EMailAddress'];
my @Attrs = ('uid','uidNumber','givenName','sn','mail');  
 
$ldap = Net::LDAP->new( '127.0.0.1' ) or die "$@";
 
# bind to open directory using $diradmin and $password
#
$mesg = $ldap->bind("uid=$diradmin,cn=users,$base",password => $password) or die $mesg->error;
                   
# iterate through open directory by uid
# - add ability to set uid from * to username given as argv                    
$mesg = $ldap->search ( base => "cn=users,$base", 
						scope=>"sub",
						filter =>'uid=*',
						attrs=>\@Attrs );
 
# process results of search
# 
# handle each of the results independently
 # ... i.e. using the walk through method
 #
 my @entries = $mesg->entries;

my $entr;
foreach $entr ( @entries ) {
  #print "dn: ", $entr->dn, "\n";
  
  my $uid=$entr->get_value('uid');
  my $firstname=$entr->get_value('givenName');
  my $lastname=$entr->get_value('sn');
  my $email=$entr->get_value('mail');

  # generate password based on firstname and lastname
  my $newpassword;
  if($firstname eq ''){
    $newpassword=uc(substr($lastname,0,1))
                .substr($lastname,1,3)
                ."2015!";
  }
  else{
    $newpassword=uc(substr($lastname,0,1))
                .substr($lastname,1,1)
                .uc(substr($firstname,0,1))
                .substr($firstname,1,1)
                ."2015!";
  }
  
  unless($uid eq 'diradmin' or $uid eq 'bciv'){
    print "uid:$uid first:$firstname last:$lastname email:$email pw:$newpassword";
    
    if($email=~m/^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,4}$/i){
      print " !";
      
      # set new password
      my $result=$ldap->set_password(newpasswd=>"$newpassword",user=>"uid=$uid,cn=users,$base");
    
      # send email notification
      my $body="$firstname $lastname:<br /><br />Your password to the <b>$system</b> at <a href=\"$url\">$url</a> has been reset as part of an system migration.<br /><br />Your new password is: $newpassword<br /><br />If you have any questions or concerns please do not hesitate to contact the VHA Innovation Help Desk at: <a href=\"$helpdeskurl\">$helpdeskurl</a> or email: <a href=\'mailto:$helpdeskemail?subject=$system Password Reset\'>$helpdeskemail</a><br /><br />--<br />$helpdeskcontact";
      my $output=`./notification-email.pl $email \"$system Password Reset\" \"$body\"`;
      `echo $output >> oditerator-mail.log`;
      `echo $uid,$firstname,$lastname,$email,$newpassword + >> oditerator.log`;
    }
    else{
      `echo $uid,$firstname,$lastname,$email,$newpassword >> oditerator.log`;
    }
    
    print "\n";
  }  
  print "#-------------------------------\n";
}

$mesg = $ldap->unbind;   
