#! /usr/bin/env perl
# Auth: Jennifer Chang
# Date: 2022/02/22
# Link: https://docs.nextstrain.org/en/latest/guides/share/sars-cov-2.html
# Desc: Loop over list of countries and create header and entries for website
# Expected input: text file delimited by |
#   Central Africa|Burundi
#   Central Africa|Cameroon
#   Central Africa|Central African Republic
#   ...

use v5.14;
use strict;
use warnings;

my $loc="";
my $geo="";
my $lc_loc="";

my %lat=();
my %long=();
my $fh;

sub print_header{
  print("  - name: $loc\n");
  print("    geo: $lc_loc\n");
  print("    parentGeo: $geo\n\n");
}

sub print_entries{
  my $url_loc=$loc;
  $url_loc=~s/\s/%20/g;

  print("  - url: https://nextstrain.org/groups/africa-cdc/ncov/$lc_loc?c=clade_membership&f_country=$url_loc&p=grid&tl=country\n");
  print("    name: $loc\n");
  print("    geo: $lc_loc\n");
  print("    level: country\n");
  print("    coords:\n");
  print("      - $long{$loc}\n");
  print("      - $lat{$loc}\n");
  print("    org:\n");
  print("      name: Africa CDC PGI\n");
  print("      url: https://africacdc.org/institutes/ipg/\n\n");
}



open($fh, '<:encoding(UTF-8)', "match.txt")
    or die "Could not open file match.txt";

while(<$fh>){
  chomp;
  my @field=split(/\t/);
  if( (scalar @field)>1){
	  $lat{$field[1]}=$field[2];
    $long{$field[1]}=$field[3];
#	  print "$field[1]($field[3],$field[2])\n";
  }
}

while(<>){
  chomp;
  if(/(.+)\|(.+)/){
    $geo=lc($1);
    $loc=$2;
    $lc_loc=lc($loc);
    $geo=~s/\s/-/g;
    $lc_loc=~s/\s/-/g;

    print_entries;
  }
}
