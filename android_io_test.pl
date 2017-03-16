#! /usr/bin/perl -w 

use strict;
use warnings;
use SVG::TT::Graph::Line;

my $lpCnt;
my $statsRpt;
my $fioCmd;
my $totalCnt;
my $deviceId;
my $adbs;
my @fields;
my @read_iops;
my @read_bw;
my @write_iops;
my @write_bw;

foreach(@ARGV)
{
	if(/--time=(\d+)/) { $totalCnt = $1; }
	elsif(/--device=(.*)/) { $deviceId = $1; }
	else { print "$0 --time=<x> --device=<id>\n"; exit;}
}

open(W, ">blk.log") or die "Failed to open blk.log";

if($deviceId) { $adbs = "-s $deviceId"; }
else { $adbs = ''; }

die "Device ID is invlaid:$deviceId\n" unless `adb $adbs root`;
`adb $adbs shell mkdir -p data/iotest`;

$fioCmd = "adb $adbs shell fio --filename=data/iotest/test0 ".
          "--ioengine=psync --direct=1 --rw=readwrite --size=500m ". 
		  "--timeout=10s --bs=4k --thread --numjobs=1 ".
		  "--rwmixread=50 --group_reporting --name=TEST0";

for($lpCnt=0; $lpCnt<$totalCnt; $lpCnt++)
{
		$fields[$lpCnt] = $lpCnt;
		print "Testing round $lpCnt -> ";
		$statsRpt = `$fioCmd`;
		if($statsRpt =~ /read:.*IOPS=(\d+),.*BW=(\d+)/)
		{
			print "R: IOPS=".$1." BW=".$2."\t";
			print W "$lpCnt $1 $2 ";
			$read_iops[$lpCnt] = $1;
			$read_bw[$lpCnt] = $2;
		}
		if($statsRpt =~ /write:.*IOPS=(\d+),.*BW=(\d+)/)
		{
			print "W: IOPS=".$1." BW=".$2."\n";
			print W "$1 $2\r\n";
			$write_iops[$lpCnt] = $1;
			$write_bw[$lpCnt] = $2;
		}
		sleep(1);
}
close(W);

# Draw a graph about IO rate
my $graph = SVG::TT::Graph::Line->new(
	{
		'height' => '4000',
		'width' => '6000',
		'min_scale_value' => '300',
		'fields' => \@fields,
	}
);

$graph->add_data(
	{
		'data' => \@read_iops,
		'title' => 'IO Testing',
	}
);

$graph->add_data(
	{
		'data' => \@read_bw,
		'title' => 'IO Testing',
	}
);

$graph->add_data(
	{
		'data' => \@write_iops,
		'title' => 'IO Testing',
	}
);

$graph->add_data(
	{
		'data' => \@write_bw,
		'title' => 'IO Testing',
	}
);

open(my $T, ">io_test.svg") || die "Failed to open io_test.svg";
select $T;
binmode $T;
print $graph->burn();
close($T);
