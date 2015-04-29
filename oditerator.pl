#!/usr/bin/perl
# If you don't know the code, don't mess around below - BCIV
use Net::LDAP;
use Net::LDAP::Extension::SetPassword;
use POSIX qw(strftime);
use Net::SMTP::SSL;

my $timestamp=strftime "%a %b %e %H:%M:%S %Y", localtime;

my $base; my $diradmin_username; my $diradmin_password; my $system; 
my $url; my $from_email; my $from_email_password;
my $helpdeskurl; my $helpdeskcontact; my $helpdeskemail;
my $smtp_server; my $smtp_port;

my $configuration_file='oditerator.config';

`rm oditerator*.log`;

# process:
#
# - this utility iterates through open directory to retrieve: 
#	uid, uidNumber, givenName, sn, mail  
#
# - a new password is generated based on a given users first and
#   lastnames plus some extra characters such as year and special character
#   which is defined my the person configuring this script
#
# - an email is sent to each user who's password has been changed
#

# todo: take input arguments for the following situations:
# individual processing of users for reset and email notification
# takes username (which may be an email address).

# see sample.config and create a configuration file based upon your environment
# update next line to require the configuration file you have configured
# set environment variables
configure($configuration_file);

my @Attrs = ('uid','uidNumber','givenName','sn','mail');  
 
$ldap = Net::LDAP->new( '127.0.0.1' ) or die "$@";
 
# bind to open directory using diradmin credentials
$mesg = $ldap->bind("uid=$diradmin_username,cn=users,$base",password => $diradmin_password) or die $mesg->error;
                   
# iterate through open directory by uid
# - add ability to set uid from * to username given as argv                    
$mesg = $ldap->search ( base => "cn=users,$base", 
						scope=>"sub",
						filter =>'uid=*',
						attrs=>\@Attrs );
 
# put search results into an array
my @entries = $mesg->entries;

# iterate through users returned
my $entr;
foreach $entr ( @entries ) {
  my $uid=$entr->get_value('uid');
  my $firstname=$entr->get_value('givenName');
  my $lastname=$entr->get_value('sn');
  my $email=$entr->get_value('mail');

  # generate password based on firstname and lastname
  my $newpassword;
  if($firstname eq ''){
    $newpassword=uc(substr($lastname,0,1))
                .substr($lastname,1,3)
                ."$extra";
  }
  else{
    $newpassword=uc(substr($lastname,0,1))
                .substr($lastname,1,1)
                .uc(substr($firstname,0,1))
                .substr($firstname,1,1)
                ."$extra";
  }

  my $sendemail='false';
  unless($uid eq 'diradmin'){
    print "uid:$uid first:$firstname last:$lastname email:$email pw:$newpassword";
    
    if($email=~m/^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,4}$/i){
      print " !E\n";
      `echo $uid,$firstname,$lastname,$email,$newpassword >> oditerator-sent.log`;
      $sendemail='true';
    }
    elsif($lastname=~m/^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,4}$/i){
      print " !L\n";
      $email=$lastname;
      `echo $uid,$firstname,$lastname,$email,$newpassword >> oditerator-sent.log`;
      $sendemail='true';
    }
    elsif($firstname=~m/^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,4}$/i){
      print " !F\n";
      $email=$firstname;
      `echo $uid,$firstname,$lastname,$email,$newpassword >> oditerator-sent.log`;
      $sendemail='true';
    }
    else{
      print " XX\n";
      `echo $uid,$firstname,$lastname,$email,$newpassword >> oditerator-no-email.log`;
    }

    # set new password
    my $result=$ldap->set_password(newpasswd=>"$newpassword",user=>"uid=$uid,cn=users,$base");

    if($sendemail eq 'true'){
      # send email notification
      my $subject="$system Password Reset";
      my $to=$email;
      my $body="$firstname $lastname:<br /><br />Your password to the <b>$system</b> at <a href=\"$url\">$url</a> has been reset as part of an system migration.<br /><br />Your new password is: $newpassword<br /><br />If you have any questions or concerns please do not hesitate to contact the VHA Innovation Help Desk at: <a href=\"$helpdeskurl\">$helpdeskurl</a> or email: <a href=\'mailto:$helpdeskemail?subject=$system Password Reset\'>$helpdeskemail</a><br /><br />--<br />$helpdeskcontact";
      `echo $uid,$firstname,$lastname,$email,$newpassword + >> oditerator.log`;
      &send_mail("$to", "$subject", "$body");
    }
  }
  print "#-------------------------------\n";
}

$mesg = $ldap->unbind;   # take down session
 
sub send_mail {
  my $to = $_[0];
  my $subject = $_[1];
  my $body = $_[2];
  my $smtp;
  if (not $smtp = Net::SMTP::SSL->new($smtp_server,Port=>$smtp_port,Debug=>1)){
    die "Could not connect to server\n";
  }
  $smtp->auth($from_email, $from_email_password) || die "Authentication failed!\n";
  $smtp->mail($from_email . "\n");
  my @recepients = split(/,/, $to);
  foreach my $recp (@recepients) {
      $smtp->to($recp . "\n");
  }
  $smtp->data();
  $smtp->datasend("MIME-Version: 1.0\n");
  $smtp->datasend("Content-Type: text/html\n");
  $smtp->datasend("From: " . $from_email . "\n");
  $smtp->datasend("To: " . $to . "\n");
  $smtp->datasend("Subject: " . $subject . "\n");
  $smtp->datasend("\n");
  $smtp->datasend($body . "\n");
  $smtp->dataend();
  $smtp->quit;
}

sub configure{
  my $file=$_[0];
  open(IN,$file) or die "Cannot read configuration file, $file : $!";
  while(<IN>){eval $_;} close(IN);
}
