#!/usr/bin/perl -w
require 5.002;
use strict;

my $root = "/home/laps/rtsys/mm5/rip/namelist";
my $header = "$root/template/header.rip";
my $outdir = "$root/grid1-asia";

# Set header variables.

my $toptitle = "USFS MM5 18km Asia Domain";
my $flmin = 0.005; my $frmax = 0.920; 
my $fbmin = 0.005; my $ftmax = 0.920;
my $timezone = 6;

# Define product names.
my @prod = qw(temp td cloud haines pbl precip precip-24 radar rh snow spd tpw type upa);

# Set product variables.
my ($xwin,$ywin,$crsa,$crsb
   ,%cint1,%cint2
   ,%hvbr,%intv,%ctym);

$xwin = "6,176"; $ywin = "6,176";
$crsa = "6.5,6.5"; $crsb = "175.5,175.5";

$cint1{"temp"} = 2;
$hvbr{"temp"} = 1;  # 0=bottom colorbar, 1=side colorbar
$intv{"temp"} = 3;
$ctym{"temp"} = 0;  # County map background (0=no, 1=yes)

$cint1{"td"} = 2;
$cint2{"td"} = 2;
$hvbr{"td"} = 1;  # 0=bottom colorbar, 1=side colorbar
$intv{"td"} = 3;
$ctym{"td"} = 0;  # County map background (0=no, 1=yes)

$cint1{"cloud"} = 2.5;
$hvbr{"cloud"} = 1;  # 0=bottom colorbar, 1=side colorbar
$ctym{"cloud"} = 0;  # County map background (0=no, 1=yes)

$hvbr{"haines"} = 1;  # 0=bottom colorbar, 1=side colorbar
$ctym{"haines"} = 0;  # County map background (0=no, 1=yes)

$hvbr{"pbl"} = 1;  # 0=bottom colorbar, 1=side colorbar
$intv{"pbl"} = 3;
$ctym{"pbl"} = 0;  # County map background (0=no, 1=yes)

$hvbr{"precip"} = 1;  # 0=bottom colorbar, 1=side colorbar
$intv{"precip"} = 3;
$ctym{"precip"} = 0;  # County map background (0=no, 1=yes)

$hvbr{"precip-24"} = 1;  # 0=bottom colorbar, 1=side colorbar
$intv{"precip-24"} = 3;
$ctym{"precip-24"} = 0;  # County map background (0=no, 1=yes)

$hvbr{"radar"} = 1;  # 0=bottom colorbar, 1=side colorbar
$intv{"radar"} = 3;
$ctym{"radar"} = 0;  # County map background (0=no, 1=yes)

$cint1{"rh"} = 5;
$hvbr{"rh"} = 1;  # 0=bottom colorbar, 1=side colorbar
$intv{"rh"} = 3;
$ctym{"rh"} = 0;  # County map background (0=no, 1=yes)

$hvbr{"snow"} = 1;  # 0=bottom colorbar, 1=side colorbar
$intv{"snow"} = 3;
$ctym{"snow"} = 0;  # County map background (0=no, 1=yes)

$hvbr{"spd"} = 1;  # 0=bottom colorbar, 1=side colorbar
$intv{"spd"} = 3;
$ctym{"spd"} = 0;  # County map background (0=no, 1=yes)

$hvbr{"tpw"} = 1;  # 0=bottom colorbar, 1=side colorbar
$ctym{"tpw"} = 0;  # County map background (0=no, 1=yes)

$hvbr{"type"} = 1;  # 0=bottom colorbar, 1=side colorbar
$ctym{"type"} = 0;  # County map background (0=no, 1=yes)

$hvbr{"upa"} = 1;  # 0=bottom colorbar, 1=side colorbar
$intv{"upa"} = 3;
$ctym{"upa"} = 0;  # County map background (0=no, 1=yes)

# Read header and color table templates.
open(IN,$header);
my @header = <IN>;
close(IN);

# Create namelist for each product.
my ($prod,$prodfile,$nlfile,$coltable,@coltable,@template);
foreach $prod (@prod) {
   $prodfile = "$root/template/$prod.rip";
   $nlfile = "$outdir/rip.in.rt$prod";
   open(OUT,">$nlfile");
   foreach (@header) {
      s/TOPTITLE/$toptitle/ if (/TOPTITLE/);
      s/FLMIN/$flmin/ if (/FLMIN/);
      s/FRMAX/$frmax/ if (/FRMAX/);
      s/FBMIN/$fbmin/ if (/FBMIN/);
      s/FTMAX/$ftmax/ if (/FTMAX/);
      s/TIMEZONE/$timezone/ if (/TIMEZONE/);
      print OUT "$_";
   }

   $coltable = "$root/template/$prod.tbl";
   open(IN,$coltable);
   @coltable = <IN>;
   close(IN);

   foreach (@coltable) {
      print OUT "$_";
   }

   open(IN,$prodfile);
   @template = <IN>;
   close(IN);

   foreach (@template) {
      s/CINT1/$cint1{"$prod"}/ if (/CINT1/);
      s/CINT2/$cint2{"$prod"}/ if (/CINT2/);
      s/HVBR/$hvbr{"$prod"}/ if (/HVBR/);
      s/INTV/$intv{"$prod"}/ if (/INTV/);
      s/XWIN/$xwin/ if (/XWIN/);
      s/YWIN/$ywin/ if (/YWIN/);
      s/CRSA/$crsa/ if (/CRSA/);
      s/CRSB/$crsb/ if (/CRSB/);
      print OUT "$_";
      if (/feld=map/ && $ctym{"$prod"}) {
         s/L4/L5/;
         s/oulw=2/oulw=1/;
         print OUT "$_";
      }
   }
   close(OUT);
}

exit;
