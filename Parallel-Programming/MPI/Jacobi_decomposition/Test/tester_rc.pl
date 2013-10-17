#!/usr/bin/perl

use warnings;
use strict;


my @sizes = (144, 288, 432);
my @cores = (1,12,24,36,48);


my $size = $ARGV[0];
my $core = $ARGV[1];


for (my $i = 0 ; $i < $size + 2 ; $i ++) {
    for (my $j = 0 ; $j < $size + 2 ; $j ++) {
	system("../jacobi $size 1000 $i $j > gold");
	system("mpirun -n $core ../pjacobi   $size 1000 $i $j > out_1");
	system("mpirun -n $core ../coljacobi $size 1000 $i $j > out_2");
        my $res = `diff3 out_1 out_2 gold`;
	if("" eq $res) {
            print "$i $j: Pass\n";
           system("rm -rf gold out_1 out_2");
        } else {
            print "$i $j: Diff\n"; 
            system("echo out_1 ; cat out_1; echo out_2 ; cat out_2; echo gold; cat  gold");
            exit(0);
        }
    } 			
}
