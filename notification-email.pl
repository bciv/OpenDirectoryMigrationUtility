#!/usr/bin/perl
# sends an email
# need to change $from and $password values on lines 15 and 16

use POSIX qw(strftime);
use Net::SMTP::SSL;

my $timestamp=strftime "%a %b %e %H:%M:%S %Y", localtime;

my $to=$ARGV[0];
my $subject=$ARGV[1];
my $message=$ARGV[2];

if(@ARGV < 2){die "options: notification-email.pl <to> <subject> <message>\n";}

my $from = 'example@mygmail.com';
my $password = 'supersecretpassword';

# Send email
&send_mail("$to", "$subject", "$message");

# routines below

sub send_mail {
  my $to = $_[0];
  my $subject = $_[1];
  my $body = $_[2];

  my $smtp;

  if (not $smtp = Net::SMTP::SSL->new('smtp.gmail.com',Port => 465,Debug => 1)) {
   die "Could not connect to server\n";
  }

  $smtp->auth($from, $password) || die "Authentication failed!\n";

  $smtp->mail($from . "\n");
  my @recepients = split(/,/, $to);
  foreach my $recp (@recepients) {
      $smtp->to($recp . "\n");
  }
  $smtp->data();
  # test
  $smtp->datasend("MIME-Version: 1.0\n");
  $smtp->datasend("Content-Type: text/html\n");
  $smtp->datasend("From: " . $from . "\n");
  $smtp->datasend("To: " . $to . "\n");
  $smtp->datasend("Subject: " . $subject . "\n");
  $smtp->datasend("\n");
  $smtp->datasend($body . "\n");
  $smtp->dataend();
  $smtp->quit;
}
