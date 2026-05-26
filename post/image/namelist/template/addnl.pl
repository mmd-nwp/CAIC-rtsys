#!/usr/bin/perl -w
require 5.002;
use strict;

my $root = "/home/laps/rtsys/mm5/rip/namelist";
my $indir = "$root/grid1";
my $outdir = "$root/grid-add";

# Define product names.
#my @prod = qw(temp td cloud haines pbl precip precip-24 radar rh snow spd tpw type upa);
my @prod = qw(temp td cloud haines pbl precip precip-24 radar rh snow spd tpw type);

# Set product variables.
my ($xwin,$ywin,$crsa,$crsb
   ,%cint1,%cint2
   ,%hvbr,%intv,%ctym);

$xwin = "91,140"; $ywin = "84,133";
$crsa = "91.5,84.5"; $crsb = "139.5,132.5";

$cint1{"temp"} = 2;
$hvbr{"temp"} = 1;  # 0=bottom colorbar, 1=side colorbar
$intv{"temp"} = 2;
$ctym{"temp"} = 1;  # County map background (0=no, 1=yes)

$cint1{"td"} = 2;
$cint2{"td"} = 2;
$hvbr{"td"} = 1;  # 0=bottom colorbar, 1=side colorbar
$intv{"td"} = 2;
$ctym{"td"} = 1;  # County map background (0=no, 1=yes)

$cint1{"cloud"} = 2.5;
$hvbr{"cloud"} = 1;  # 0=bottom colorbar, 1=side colorbar
$ctym{"cloud"} = 1;  # County map background (0=no, 1=yes)

$hvbr{"haines"} = 1;  # 0=bottom colorbar, 1=side colorbar
$ctym{"haines"} = 1;  # County map background (0=no, 1=yes)

$hvbr{"pbl"} = 1;  # 0=bottom colorbar, 1=side colorbar
$intv{"pbl"} = 2;
$ctym{"pbl"} = 1;  # County map background (0=no, 1=yes)

$hvbr{"precip"} = 1;  # 0=bottom colorbar, 1=side colorbar
$intv{"precip"} = 2;
$ctym{"precip"} = 1;  # County map background (0=no, 1=yes)

$hvbr{"precip-24"} = 1;  # 0=bottom colorbar, 1=side colorbar
$intv{"precip-24"} = 2;
$ctym{"precip-24"} = 1;  # County map background (0=no, 1=yes)

$hvbr{"radar"} = 1;  # 0=bottom colorbar, 1=side colorbar
$intv{"radar"} = 2;
$ctym{"radar"} = 1;  # County map background (0=no, 1=yes)

$cint1{"rh"} = 5;
$hvbr{"rh"} = 1;  # 0=bottom colorbar, 1=side colorbar
$intv{"rh"} = 2;
$ctym{"rh"} = 1;  # County map background (0=no, 1=yes)

$hvbr{"snow"} = 1;  # 0=bottom colorbar, 1=side colorbar
$intv{"snow"} = 2;
$ctym{"snow"} = 1;  # County map background (0=no, 1=yes)

$hvbr{"spd"} = 1;  # 0=bottom colorbar, 1=side colorbar
$intv{"spd"} = 2;
$ctym{"spd"} = 1;  # County map background (0=no, 1=yes)

$hvbr{"tpw"} = 1;  # 0=bottom colorbar, 1=side colorbar
$ctym{"tpw"} = 1;  # County map background (0=no, 1=yes)

$hvbr{"type"} = 1;  # 0=bottom colorbar, 1=side colorbar
$ctym{"type"} = 1;  # County map background (0=no, 1=yes)

$hvbr{"upa"} = 1;  # 0=bottom colorbar, 1=side colorbar
$intv{"upa"} = 2;
$ctym{"upa"} = 1;  # County map background (0=no, 1=yes)

# Read exisitng namelist.
my ($header,@header,$prod,$prodfile,$nlfile,$coltable,@coltable,@template,$first);
foreach $prod (@prod) {
   $header = "$indir/rip.in.rt$prod";
   open(IN,$header);
   my @header = <IN>;
   close(IN);

# Create added namelist for each product.
   $prodfile = "$root/template/$prod"."-eng.rip";
   $nlfile = "$outdir/rip.in.rt$prod";
   open(OUT,">$nlfile");
   foreach (@header) {
      print OUT "$_";
   }

   open(IN,$prodfile);
   @template = <IN>;
   close(IN);

   $first = 1;
   foreach (@template) {
      s/CINT1/$cint1{"$prod"}/ if (/CINT1/);
      s/CINT2/$cint2{"$prod"}/ if (/CINT2/);
      s/HVBR/$hvbr{"$prod"}/ if (/HVBR/);
      s/INTV/$intv{"$prod"}/ if (/INTV/);
      s/XWIN/$xwin/ if (/XWIN/);
      s/YWIN/$ywin/ if (/YWIN/);
      s/CRSA/$crsa/ if (/CRSA/);
      s/CRSB/$crsb/ if (/CRSB/);
      if ($first) {
         print OUT "# Utah Domain.\n";
         $first = 0;
      } else {
         print OUT "$_";
      }
      if (/feld=map/ && $ctym{"$prod"}) {
         s/L4/L5/;
         s/oulw=2/oulw=1/;
         print OUT "$_";
      }
   }
   close(OUT);
}

exit;
