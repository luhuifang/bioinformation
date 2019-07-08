#!/usr/bin/perl -w
use strict;
use SVG;

die "perl $0 <m8_file> <query_len_list> <target_len_list>\n" unless (@ARGV >=3);
my $m8f = shift;
my $qlenf = shift;
my $tlenf = shift;

my %qlen = ();
&readLenFile($qlenf, \%qlen);
my %tlen = ();
&readLenFile($tlenf, \%tlen);

my ($qlen_total, $tlen_total) = (0 , 0);
my %q_tmp = ();
my %t_tmp = ();
open M8, "<$m8f" or die $!;
while(my $line = <M8>){
	chomp $line;
	my ($query, $target, $qstart, $qend, $tstart, $tend) = (split /\s+/, $line)[0,1,6,7,8,9];
	#print "$query, $target, $qstart, $qend, $tstart, $tend\n";
	if(!exists $q_tmp{$query}){
		$qlen_total += $qlen{$query};
		$q_tmp{$query}=1;
	}

	if(!exists $t_tmp{$target}){
		$tlen_total += $tlen{$target};
		$t_tmp{$target}=1;
	}
}
close M8;

my $width = 400;
my $height = 400;
my $svg = SVG->new(width=>$width, height=>$height);

my $row_scal = ($width-70)/$tlen_total;
my $col_scal = ($height-70)/$qlen_total;


#Origin of coordinate axis
my $x = 50;
my $y = $height - 50;

$svg->rect(x=>50, y=>20, width=>$width-70, height=>$height-70, 'stroke', 'black', 'stroke-width', 1, 'fill-opacity', 0);

my %query_y = ();
my %target_x = ();

open M8, "<$m8f" or die $!;
while(my $line = <M8>){
	chomp $line;
	my ($query, $target, $qstart, $qend, $tstart, $tend) = (split /\s+/, $line)[0,1,6,7,8,9];

	if( !exists $query_y{$query}){
		$query_y{$query} = [$y, $y-($col_scal*$qlen{$query})];
		$y = $y-($col_scal*$qlen{$query});
	}

	if( !exists $target_x{$target}){
		$target_x{$target} = [$x, $x+($row_scal*$tlen{$target})];
		$x = $x+($row_scal*$tlen{$target});
	}

	my $plot_x1 = $target_x{$target}[0] + $row_scal*$tstart;
	my $polt_y1 = $query_y{$query}[0] - $col_scal*$qstart;
	my $plot_x2 = $target_x{$target}[0] + $row_scal*$tend;
	my $polt_y2 = $query_y{$query}[0] - $col_scal*$qend;
	$svg->line(x1=>$plot_x1, y1=>$polt_y1, x2=>$plot_x2, y2=>$polt_y2 ,'stroke', 'red', 'stroke-width', 1);

	my $rect_x = $plot_x1 < $plot_x2 ? $plot_x1:$plot_x2;
	$svg->rect(x=>$rect_x, y=>$height-45, width=>abs($plot_x2-$plot_x1)+1, height=>5, 'stroke', 'black', 'stroke-width', 0, 'fill-opacity', 0.5, 'fill', 'blue');

}
close M8;

foreach my $q(keys %query_y){
	my $plot_x = 15;
	my $plot_y = $query_y{$q}[0] + ($query_y{$q}[1] - $query_y{$q}[0])/2;
	#$svg->text(x=>$plot_x, y=>$plot_y, -cdata=>$q, 'font-size', 8, 'text-anchor', 'middle');

	my $p_l_x1 = 50;
	my $p_l_x2 = 45;
	my $p_l_y1 = $query_y{$q}[1];
	my $p_l_y2 = $query_y{$q}[1];
	$svg->line(x1=>$p_l_x1, y1=>$p_l_y1, x2=>$p_l_x2, y2=>$p_l_y2 ,'stroke', 'black', 'stroke-width', 1);
}

foreach my $t(keys %target_x){
	my $plot_y = $height-20;
	my $plot_x = $target_x{$t}[0] + ($target_x{$t}[1] - $target_x{$t}[0])/2;
	#$svg->text(x=>$plot_x, y=>$plot_y, -cdata=>$t, 'font-size', 8, 'text-anchor', 'middle');
	
	my $p_l_x1 = $target_x{$t}[1];
	my $p_l_x2 = $target_x{$t}[1];
	my $p_l_y1 = $width-50;
	my $p_l_y2 = $width-45;
	$svg->line(x1=>$p_l_x1, y1=>$p_l_y1, x2=>$p_l_x2, y2=>$p_l_y2 ,'stroke', 'black', 'stroke-width', 1);
}



print $svg->xmlify();
## ======================= Sub ===================================
sub readLenFile{
	my ($file, $len) = @_;
	open LEN, "<$file" or die $!;
	while(my $line = <LEN>){
		chomp $line;
		my ($id, $lens) = (split /\s+/, $line)[0,1];
		$$len{$id} = $lens;
	}
	close LEN;
}




