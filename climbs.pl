#!/usr/bin/perl
#
# Takes a raw file (fw-climbs.raw) and generates HTML pages with climbing
# lists sorted by date, area, difficulty, quality and people. The following
# files are generated
#      fw-date.html fw-area.html fw-grade.html fw-quality.html fw-people.html
#
# The script uses climbs-frame.html to generate the stuff around the actual
# data. Modify that file if you need different headers, footers or whatever.
#
# Author:   Frederik Willerup (fw)
# Created:  January 1997
# Modified: January 2022 (mw) mathias@willerup.com
#

# How to: 
# print full date in mw-date
# include comments on people/difficulty/area
# print full area (maybe without the country)
# get the stats to work (index-frame)

# require("extenv.pl");

# Some constants that depend on the platform we run on
$thedate = `date +"%e %B %y"`;
$src = ".";
$dest = "./html";

$Istar1 = '&#129482;'; #ice
$Istar2 = '&#127956;'; #mountain
$Istar3 = '&#129686;'; #cave &#128294; (flashlight)
$Istar4 = '&#128074;'; #boulder 
$Istar5 = '&#128279;'; #Via Ferrata 
$Istar6 = '&#129343;'; #dive
$Istar7 = '&#129666;'; #paraglider
$Istar8 = '&#127940; &#9973;'; #surf and sail
$Istar9 = '&#127938; &#128095;'; #snow and run 

# Global Routines and things
@months = ('January','February','March','April','May','June','July',
           'August','September','October','November','December');
%ukadj = ('D',200,'VD',400,'HVD',450,'S',500,'HS',600,'VS',700,'HVS',850,'E1',1000,'E2',1060,'E3',1100,'E4',1125,'E5',1200,'E6',1280,'E7',1300);
%post = ('a',0,'b',25,'c',50,'d',75);
%french = ('III',600,'F3',600,'IV',750,'F4',750,'F5',900,'V',900,'F6a',1020,'F6b',1085,'F6c',1100,'F7a',1180,'F7b',1250,'F7c',1300);
%ice = ('W2',700,'W3',750,'W4',800,'W5',900,'W6',1020,'M6',1085,'M7',1100);
%uk = ('4a',600,'4b',650,'4c',700,'5a',850,'5b',900,'5c',1050,'6a',1150,'6b',1200,'6c',1250);
sub byroutes {$stat{$b} <=> $stat{$a};}


sub gradevalue {
  local($grade) = @_;
  local($adj);

  $g = $grade;
  return 0 unless ($g);
  $g =~ s/\+|\-//;
  $g =~ s/^\s+//;

  $num2 = 0;

  if (($a,$b) = $g =~ /5\.(\d+)([abcd]?)/) {
    # us grade
    $num1 = $a * 100 + $post{$b};
  } elsif ($g =~ /^F|I/) {
    # french grade
    $num1 = $french{$g};
  } elsif ($g =~ /^W|M/) {
    # ice grade
    $num1 = $ice{$g};
  } elsif (($adj) = $g =~ /^(E\d|HVS|VS|HS|S|HVD|VD|D)\b\s*/) {
    $num1 = $ukadj{$adj} + $uk{$'} / 50;
  } else {
    $num1 = $uk{$g};
  }
  
  $num1 += 6 if ($grade =~ /\+/);
  $num1 -= 6 if ($grade =~ /\-/);
    
  $num1;
}


sub basegrade {
  # e.g., E1 4a,5a,4c => E1 5a
  local($g) = @_;
  local($adj);

  $g =~ s/\[[^\]]+\]//g;
  $g =~ s/^\s+//;
  # extract adjective grade into $adj (if there is one)
  if (($adj) = $g =~ /^(E\d|HVS|VS|HS|S|HVD|VD|D)\b\s*/) {
     $g = $';
  }
  return $adj unless ($g);
  $g =~ s/\s//g;
  $max = '';
  foreach $gr(split(',', $g)) {
    $max = $gr if ($gr ne '-' && &gradevalue($gr) > &gradevalue($max));
  }
  "$adj $max";
}


sub generate {
# Read climbs file into
#    %cdate, %carea, %cpeople, %cgrade, %cstars
#    %people=names, %area=area names
($theinit) = @_;
local($people,$short,$totalroutes,$totalheight);
local(%Yroutes,%Yheight,%Y3star,%Y8star,%Ylead,%Ysec,%Ysport,%Yepoints);
local(%cdate,%carea,%cpeople,%cgrade,%cstars,%lpeople,%larea,%stat);

$thename = "Frederik" if ($theinit eq 'fw');
$thename = "Mathias" if ($theinit eq 'mw');
$thelname = $thename;
$thelname =~ tr/[A-Z]/[a-z]/;

print "Updating ${thename}'s ($theinit) climbing pages\n";

open(CLIMBS, "$src/$theinit-climbs.txt") || die "Couldn't open data file ($src/$theinit-climbs.txt)";

while (<CLIMBS>) {
    chop;

    # People list
    $people = 1 if (/^\#.*People/);
    ($short,$name) = /^(\w+)\=(.*)$/;
    if ($people && $short) {
        $lpeople{$short} = $name;
    }
    # Area list
    elsif ($short) {
        $name =~ s/\*\*\*\*\*\*\*\*\*/$Istar9/;
        $name =~ s/\*\*\*\*\*\*\*\*/$Istar8/;
        $name =~ s/\*\*\*\*\*\*\*/$Istar7/;
        $name =~ s/\*\*\*\*\*\*/$Istar6/;
        $name =~ s/\*\*\*\*\*/$Istar5/;
        $name =~ s/\*\*\*\*/$Istar4/;
        $name =~ s/\*\*\*/$Istar3/;
        $name =~ s/\*\*/$Istar2/;
        $name =~ s/\*/$Istar1/;
        $larea{$short} = $name;
    }
    # Climbs list
    elsif (/^\S.*;/) {
        s/(\*+)//;
        $stars = $1;
        $nstars = 0;
        $nstars = 1 if ($stars =~ /\*/ || /<1>/);
        $nstars = 2 if ($stars =~ /\*\*/ || /<2>/);
        $nstars = 3 if ($stars =~ /\*\*\*/ || /<3>/);
        $nstars = 4 if ($stars =~ /\*\*\*\*/ || /<4>/);
        $nstars = 5 if ($stars =~ /\*\*\*\*\*/ || /<5>/);
        $nstars = 6 if ($stars =~ /\*\*\*\*\*\*/ || /<6>/);
        $nstars = 7 if ($stars =~ /\*\*\*\*\*\*\*/ || /<7>/);
        $nstars = 8 if ($stars =~ /\*\*\*\*\*\*\*\*/ || /<8>/);
        $nstars = 9 if ($stars =~ /\*\*\*\*\*\*\*\*\*/ || /<9>/);
	  $stars = "";
	  $stars = $Istar1 if ($nstars == 1);
	  $stars = $Istar2 if ($nstars == 2);
	  $stars = $Istar3 if ($nstars == 3);
	  $stars = $Istar4 if ($nstars == 4);
	  $stars = $Istar5 if ($nstars == 5);
	  $stars = $Istar6 if ($nstars == 6);
	  $stars = $Istar7 if ($nstars == 7);
	  $stars = $Istar8 if ($nstars == 8);
	  $stars = $Istar9 if ($nstars == 9);

        ($date,$area,$name,$grade,$height,$people,$icons,$photo) = split(';');

        # remove some spaces
        $area =~ s/^\s*//;
        $grade =~ s/^\s*//;
        $name =~ s/^\s*//;
        $height =~ s/^\s*//;
        $people =~ s/^\s*//;

        # fiddle with data (insert references etc)
        $sarea = "<a href=\"$theinit-area.html#$area\">$area</a>";
        print "Warning: $area is not a valid area\n" if (!$larea{$area});
        $speople = $people;
        $speople =~ s/\b([A-Z]+)\b/x\1x/g;
        while ($speople =~ /x[A-Z]+x/) {
            $speople =~ s/x([A-Z]+)x/<a href=\"$theinit-people.html\#\1\">\1<\/a>/;
            print "Warning: $1 is not in the person list\n" if (!$lpeople{$1});
        }
        $name = "$name";
        $h = $1 if ($height =~ /^([0-9]*)ft/);   # Height is in feet
        $h = $1*3 if ($height =~ /^([0-9]*)m/);  # Height is in meters
        $h = 50 if ($height =~ /^\s*$/);         # Assume 50ft if there is no height
        $totalroutes++, $totalheight += $h;
#        $totalroutes++, $totalheight += $h if ($people =~ /,/); # this route was climbed on two diff. occations
        $height = '' unless ($height);

        $thelegend = '&#129336;Whip &#128175;Top100 &#129344;Bail &#129528;Wish 
        
        &#128128;Suicide &#128170;Achievement &#128293;Mindblower &#127868;Aid &#129422;Multipitch';

        # Photo
        $photo =~ s/<I ([^\>]*)>/<img src="\1" width="100%"><\/img><br>/g;
        
        # Stars
        $icons =~ s/<1S>/&#10024;/g;  #1 &#128261; star 
        $icons =~ s/<2S>/&#127775;/g; #2 &#128262; stars
        $icons =~ s/<3S>/&#11088;/g;  #3 stars

        # Caving
        $icons =~ s/<C1>//g; # &#128154; green helemt
        $icons =~ s/<C2>//g; # &#128153; blue helmet
        $icons =~ s/<C3>//g; # &#129505; red helmet
        $icons =~ s/<C4>//g; # &#128420; black helmet

        # Icons
        $icons =~ s/<A>/&#128170;/g; #achievement
        $icons =~ s/<B>/&#128297;/g; #bolt
        $icons =~ s/<E>/&#129422;/g; #multipitch
        $icons =~ s/<G>/&#128074;/g; #boulder
        $icons =~ s/<L>/&#128280;/g; #wish  teddybear &#129528;
        $icons =~ s/<Q>/&#129344;/g; #bail
        $icons =~ s/<M>/&#128293;/g; #mindblower
        $icons =~ s/<T>/&#128175;/g; #bulls eye
        $icons =~ s/<R>/&#9748;/g;   #rainy
        $icons =~ s/<S>/&#127780;/g; #sunny
        $icons =~ s/<W>/&#129336;/g; #whipper
        $icons =~ s/<X>/&#128128;/g; #suicide 
        $icons =~ s/<Y>/&#127788;/g; #windy
        $icons =~ s/<F>/&#127868;/g; #aid
        $icons =~ s/<Z>/&#127768;/g; #night 
        $icons =~ s/<H>/&#129508;/g; #glove 
        $icons =~ s/<N ([^\>]*)>/<a href="\1" class="report">&#128218;Report<\/a>/g;
        $icons =~ s/<P ([^\>]*)>/<a href="\1" class="photo">&#128248;<\/a>/g;
        $icons =~ s/<O ([^\>]*)>/<a href="\1" class="map">&#129517;Topo<\/a>/g;
        $icons =~ s/<K ([^\>]*)>/<a href="\1" class="map">&#127916;Video<\/a>/g;
        $icons =~ s/<D ([^\>]*)>/<a href="\1">Link<\/a>/g;
 
        #lizard &#129422;
        #compass &#129517;
        #video clapper &#127916;
        #firecracker &#129512;
        #pill &#128138;
        #rock &#129704;
        #chili 127798
        #strenous 128170
        #top 100  128175   127913
        #bulls eye 127919
        #chain 128279
        #bail 128281
        #fire 128293
        #benighted 128294 (torch) 128367 (candle) 127768 (moon)
        #bolt 128297
        #suicide 128299  128128
        #gated 128477  128679  128683
        #climber 129495
        #flash 9889
        #axe 9935
        #helmet 9937
        #camp 9978
        #temperature 127777
        #vegetated 127812 
        #mountain 127956
        #desert 127964
        #fistbump 128074
        #diamond 128142  
        #explode 128165
        #cloud 9925
        #label 127991
        #search &#128269;
        

        #$icons = sprintf("<%d>",$nstars) . $icons if ($nstars && !($icons =~ /<\d>/));
        #$icons =~ s/<1>/$Istar1/g;
        #$icons =~ s/<2>/$Istar2/g;
        #$icons =~ s/<3>/$Istar3/g;
        $icons =~ s/<\d>//g;

        $icons = '' if ($icons =~ /^\s*$/);

        # %date
        $d = '0'; $m = '0'; $y = '0';
        ($d,$m,$y) = split('-', $date);
        if ($y) { 
            $ndate = sprintf("%04d%02d",$y,$m);
            $sdate = sprintf("%04d%02d%02d", $y, $m, $d);
            $date = sprintf("$d-%s-%s", substr(@months[$m-1],0,3), substr($y,2,2));
        } else {
            $ndate = "000000";
            $sdate = "00000000";
            $date = "";
        }
        $d =~ s/1$/1/;
        $d =~ s/2$/2/;
        $d =~ s/3$/3/;
        $d =~ s/([04-9])$/\1/;
        $d =~ s/(1[0-9])../\1/;
	  $cdate{$ndate} .= "|" if ($cdate{$ndate});
        $cdate{$ndate} .= "$sdate~$d~$name~$sarea~$grade~$height~$speople~$icons~$photo~$stars~";

        # %area
        $carea{$area} .= "|" if ($carea{$area});
        $carea{$area} .= "$name~$grade~$height~$speople~$date~$icons~$stars~";

        # %people
        $tmp = $people;
        while (($p) = $tmp =~ /([A-Z]+)/) {
            $cpeople{$p} .= "|" if ($cpeople{$p});
            $cpeople{$p} .= "$sdate~$date~$name~$sarea~$grade~$height~$speople~$icons~$stars~";
            $tmp =~ s/[A-Z]+//;
        }

        # %stars
        if ($nstars) {
            $cstars{$nstars} .= "|" if ($cstars{$nstars});
            $cstars{$nstars} .=  "$sdate~$date~$name~$sarea~$grade~$height~$speople~$icons~$stars~";

        }
#        if ($mind) {
#           $cstars{4} .= "|" if ($cstars{4});
#          $cstars{4} .=  "$sdate~$date~$name~$sarea~$grade~$height~$speople~$icons~$stars~";
# }

        # @grade
        $base = &basegrade($grade);
        $numgrade = &gradevalue($base);
        $sys = 'French';
        $sys = 'Ice' if ($base =~ /W|M/);
        $sys = 'UK' if ($base =~ /E|S|[^ATE]D/);
        $sys = 'US (YDS)' if ($base =~ /5\./);
#$sys = 'Lead';
#$sys = 'Alt. lead' if ($people =~ /alt/);
#$sys = 'Second' if ($people =~ /sec/);
#$sys = 'Top rope' if ($people =~ /top/);
#$sys = 'Solo' if ($people =~ /solo/);
#print "$numgrade - $base - $grade\n";

        $cgrade{$sys} .= "|" if ($cgrade{$sys});
        $cgrade{$sys} .= "$numgrade~$date~$name~$sarea~$grade~$height~$speople~$icons~$stars~";

        # Yearly stats
        $Yroutes{$y}++, $Yheight{$y} += $h;
    	  $Y1star{$y}++ if ($nstars == 1);
    	  $Y2star{$y}++ if ($nstars == 2);
    	  $Y3star{$y}++ if ($nstars == 3);
    	  $Y4star{$y}++ if ($nstars == 4);
    	  $Y5star{$y}++ if ($nstars == 5);
    	  $Y6star{$y}++ if ($nstars == 6);
    	  $Y7star{$y}++ if ($nstars == 7);
    	  $Y8star{$y}++ if ($nstars == 8);
    	  $Y9star{$y}++ if ($nstars == 9);
        if (($ep) = $grade =~ /\bE(\d+)/) {
          $Yepoints{$y} += $ep;
        }
      
        if ($people =~ /-/) {
          #unclean
        } elsif ($icons =~ /bolted/) {
           # sports route
           if ($speople =~ /lead|alt/) {
             $Ysport{$y} = $base, $YDsport{$y} = $ndate if ($numgrade > &gradevalue($Ysport{$y}));
           }
        } elsif ($speople =~ /lead|alt/) {
           # trad lead
           $Ylead{$y} = $base, $YDlead{$y} = $ndate if ($numgrade > &gradevalue($Ylead{$y}));
        } else {
           # trad second
           $Ysec{$y} = $base, $YDsec{$y} = $ndate if ($numgrade > &gradevalue($Ysec{$y}));
        }

    }
    # Comment for previous climb
    elsif (/^\s+/)
    {
        $comment = $';
        $comment =~ s/\|//g;
        $cdate{$ndate} .= $comment if ($date);
        $carea{$area} .= $comment if ($area);
        # $cgrade{$sys} .= $comment if ($sys);
        $cstars{$nstars} .= $comment if ($nstars);
        if ($people && $comment) {
          $tmp = $people;
          while (($p) = $tmp =~ /([A-Z]+)/) {
            $cpeople{$p} .= $comment;
            $tmp =~ s/[A-Z]+//;
          }
        }
    }
}
close(CLIMBS);


# Output: write the files
open(IN, "$src/frame.html") || die "error: failed to open $src/climbs-frame.html";
open(AREA, "> $dest/$theinit-area.html") || die "error: failed to open $dest/$theinit-area.html";
open(DATE, "> $dest/$theinit-date.html") || die "error: failed to open $dest/$theinit-date.html";
open(PHOTO, "> $dest/$theinit-photo.html") || die "error: failed to open $dest/$theinit-photo.html";
open(PEOPLE, "> $dest/$theinit-people.html") || die "error: failed to open $dest/$theinit-people.html";
open(STARS, "> $dest/$theinit-quality.html") || die "error: failed to open $dest/$theinit-quality.html";
open(GRADE, "> $dest/$theinit-grade.html") || die "error: failed to open $dest/$theinit-grade.html";

while (<IN>) {
    s/\{I\}/$theinit/g;
    s/\{DATE\}/$thedate/g;
    s/\{SORT\}/x/g;
    s/\{NAME\}/$thename/g;
    s/\{LEGEND\}/$thelegend/g;
    s/\{LNAME\}/$thelname/g;

    if (/\{DATA\}/) {
        # Write AREA
        %stat = ();
        foreach $area(sort keys %carea) {
            $output = "<a name=\"$area\"></a><hr class=grey><h2>$larea{$area} ($area)</h2>\n";
            $output .= "";
            $output .= "";

            $h = 0; $r = 0;
            foreach (sort {$b<=>$a} split('\|', $carea{$area})) {
                ($name,$grade,$height,$people,$date,$icons,$stars,$comment) = split('~');
                $output .= "<hr class=grey>";
                $output .= "<div><span class=name2>$name </span><span class=grade>$people $date $stars $icons</span></div>";
                # $output .= "<div class=details>$height / </div> \n ";
                #if ($comment) {
                #    $output .= "<div class=comment>$comment</div>\n";
                #}

                $height = $1 if ($height =~ /^([0-9]*)ft/);   # Height is in feet
                $height = $1*3 if ($height =~ /^([0-9]*)m/);  # Height is in meters
                $height = 30 if ($height =~ /^\s*$/);         # Assume 30ft if there is no height
                $r++; $h += $height;
            }
            $output .= "\n\n";
            $carea{$area} = $output;
            $stat{$area} = "$r $h";
        }
        # Print statistics for each area
        print AREA "<hr class=grey><h2>Area index</h2><table width=100%>\n";
        print AREA "<tr><td></td><td><i>Area</i></td>";
        print AREA "<td align=right><i>Routes</i></td><td align=right><i>Height</i></td></tr>\n";
        foreach $area(sort byroutes keys %stat) {
            ($routes,$height) = split(' ', $stat{$area});
            print AREA "<tr><td><a href=\"#$area\">$area</a></td><td>$larea{$area}</td>";
            printf AREA "<td align=right>$routes</td><td align=right>%dm</td></tr>\n", $height / 3;
        }

        print AREA "<tr><td></td><td align=right><i>Total:</i></td>";
        printf AREA "<td align=right>$totalroutes</td><td align=right>%dm</td></tr>\n", $totalheight / 3;
        print AREA "</table>\n";
        # Print all area data
        foreach $area(sort byroutes keys %stat) {
            print AREA $carea{$area};
        }

        # Write DATE
        $latest = 0;
        $l = "\n";

        foreach $sdate(sort {$b<=>$a} keys %cdate) {
            $title = @months[substr($sdate,4,2)-1].' '.substr($sdate,0,4);
            $title = "Wish list" if ($sdate == 0);

            print DATE "<h2><a name=\"$sdate\">$title</a></h2>\n";
            print DATE "$Hdate" if ($sdate > 0);
            print DATE "<hr class=grey>\n";

            foreach (sort {$b<=>$a} split('\|', $cdate{$sdate})) {
                ($x,$date,$name,$area,$grade,$height,$people,$icons,$photo,$stars,$comment) = split('\~');
                # print DATE "<hr class=grey>\n";
# HOW TO PRINT FULL DATE  # print DATE "<a name=\"$date\"></a>";
                print DATE "<div>";
                # print DATE "$photo";
                print DATE "<b>$name</b> $grade,
                $height $stars $icons $people\n";
                # print DATE "<div class=details>$area / $height /  / </div>\n";  
            if ($comment) {
                print DATE "<div class=comment>$comment</div>";
                }
                print DATE "</div><hr class=grey>";
            }
            print DATE "\n\n";
        }
        $l .= "";
        $latest{$theinit} = $l;

        # Write PHOTO
        $latest = 0;
        $l = "\n";

        foreach $sdate(sort {$b<=>$a} keys %cdate) {
            $title = @months[substr($sdate,4,2)-1].' '.substr($sdate,0,4);
            $title = "Wish list" if ($sdate == 0);

            print PHOTO "<h2><a name=\"$sdate\">$title</a></h2>\n";
            print PHOTO "$Hdate" if ($sdate > 0);
            print PHOTO "\n";

            foreach (sort {$b<=>$a} split('\|', $cdate{$sdate})) {
                ($x,$date,$name,$area,$grade,$height,$people,$icons,$photo,$stars,$comment) = split('\~');
                print PHOTO "<hr class=grey>\n";
# HOW TO PRINT FULL PHOTO  # print PHOTO "<a name=\"$date\"></a>";
                print PHOTO "<div>";
                print PHOTO "$photo";
                print PHOTO "<span class=name2>$name </span><span class=grade>$grade $stars $icons $people</span>\n";
                # print PHOTO "<div class=details>$area / $height /  / </div>\n";  
            if ($comment) {
                print PHOTO "<div class=comment>$comment</div>";
                }
                print PHOTO "</div>";
            }
            print PHOTO "\n\n";
        }
        $l .= "";
        $latest{$theinit} = $l;

        # Write PEOPLE
        %stat = ();
        foreach $person(sort keys %cpeople) {
            $output = "<a name=\"$person\"></a><hr class=grey><h2>$lpeople{$person} ($person)</h2>\n";
            $output .= "";
            $output .= "";

            $h = 0; $r = 0;
            foreach (sort {$b<=>$a} split('\|', $cpeople{$person})) {
                ($x,$date,$name,$area,$grade,$height,$people,$icons,$stars,$comment) = split('~');
                $output .= "<hr class=grey>
                <div class=card><span class=tiny>$date $area</span><br>
                $stars <span class=name2>$name</span> <span class=grade> $grade, $height $icons</span></div>";
                $output .= "<div class=comment>$comment</div>" if ($comment);
                
                $height = $1 if ($height =~ /^([0-9]*)ft/);   # Height is in feet
                $height = $1*3 if ($height =~ /^([0-9]*)m/);  # Height is in meters
                $height = 50 if ($height =~ /^\s*$/);         # Assume 50ft if there is no height
                $r++; $h += $height;
            }
            $output .= "\n\n";
            $cpeople{$person} = $output;
            $stat{$person} = "$r $h";
        }
        # Print statistics for each person
        print PEOPLE "<hr class=grey><h2>Climbing Partners</h2><table width=100%>\n";
        print PEOPLE "<tr><td><i>Initials</i></td><td><i>Person</i></td>";
        print PEOPLE "<td align=right><i>Routes</i></td><td align=right><i>Height</i></td></tr>\n";
        foreach $person(sort byroutes keys %stat) {
            ($routes,$height) = split(' ', $stat{$person});
            print PEOPLE "<tr><td><a href=\"#$person\">$person</a></td><td>$lpeople{$person}</td>";
            printf PEOPLE "<td align=right>$routes</td><td align=right>%dm</td></tr>\n", $height / 3;
        }
        print PEOPLE "<tr><td></td><td align=right><i>Total:</i></td>";
        printf PEOPLE "<td align=right>$totalroutes</td><td align=right>%dm</td></tr>\n", $totalheight / 3;
        print PEOPLE "</table>\n";

        # Print all the people data
        foreach $person(sort byroutes keys %stat) {
            print PEOPLE $cpeople{$person};
        }
        
        # Write STARS
        foreach $stars(sort {$c<=>$b} keys %cstars) {
            @stars = ("Ice climbs $Istar1", "Mountains $Istar2", "Caves $Istar3", "Blocs $Istar4", 
            "Via Ferrata $Istar5", "Dive $Istar6", "Paraglider $Istar7", "Surf $Istar8", "Snow and Run $Istar9");
            printf STARS "<h2>%s</h2>\n", $stars[$stars-1];
            print STARS "";
            print STARS "";

            foreach (sort {$b<=>$a} split('\|', $cstars{$stars})) {
                ($x,$date,$name,$area,$grade,$height,$people,$icons,$s,$comment) = split('~');
                print STARS "<hr class=grey>";
                print STARS "<div class=name2>$name <span class=grade>$grade </span></div>";
                print STARS "<div class=details>$area / $height / $people / $icons</div>";
                if ($comment) {
                  print STARS "<div class=comment>$comment</div>";
                }
            }
            print STARS "<hr class=grey>\n";
        }

        # Write Difficulty
      %table = ();
      foreach $sys(keys %cgrade) {
	  $output = "";
           $output .= "<a name=\"$sys\"></a><h2>$sys Graded Climbs</h2>\n";
           $output .= "";
           $output .= "";
           %list = ();
           foreach (sort {$b<=>$a} split('\|', $cgrade{$sys})) {
               ($x,$date,$name,$area,$grade,$height,$people,$icons,$stars,$comment) = split('~');
               $g = &basegrade($grade);
               $g =~ s/\s\S*$//;
               $list{$g}++;                   

               $output .= "<hr class=grey><div><span class=name2>$name</span> <span class=grade>$grade</span>, $area</a></div>";
               $output .= "<div class=details>$height / $people / $icons / $stars / $date</div>\n";
           }
           $output .= "\n\n";

####### table of number of routes in each grade
#	     print GRADE "Grade Routes\n";
#	     foreach $g(keys %list) {
#		 print GRADE "$g $list{$g}\n";
#           }
#           print GRADE "\n\n";

	     print GRADE $output;
      }
        
    } else {
        print AREA;
        print DATE;
        print PHOTO;
        print PEOPLE;
        print STARS;
        print GRADE;
    }
}
close(IN);
close(AREA);
close(DATE);
close(PHOTO);
close(PEOPLE);
close(STARS);
close(GRADE);

###### Generate the "statistics" section
$Xroutes = 0, $Xheight = 0, $X3star = 0, $X8star = 0;
$s = "<table width=100%>\n<tr>";
$s .= "<td>Year</td>";
$s .= "<td>&#129704; Rock</td>";
#$s .= "<td>Height</td>";
$s .= "<td>$Istar1 Ice</td>";
#$s .= "<td>$Istar2 Mnt</td>";
$s .= "<td>$Istar3 Cave</td>";
#$s .= "<td>$Istar4 Bldr</td>";
#$s .= "<td>$Istar5 VF</td>";
#$s .= "<td>$Istar6 Dve</td>";
#$s .= "<td>$Istar7 Prp</td>";
#$s .= "<td>$Istar8 Srf</td>";
#$s .= "<td>$Istar9 Snw</td>";
#$s .= "<td>$Istar10 Run</td>";
$s .= "<td>&#129422; Lead</td>";
#$s .= "<td>Second</td>";
#$s .= "<td>Sport</td>\n";
$s .= "<td>&#128293; Epts</td></tr>\n";
#$s .= "<tr><td colspan=13><hr></td></tr>";
foreach $year(sort {$b<=>$a} keys %Yroutes) {
   $Yroutes{$year} = "&nbsp;" unless ($Yroutes{$year});
   $Yheight{$year} = "&nbsp;" unless ($Yheight{$year});
   $Y1star{$year} = "&nbsp;" unless ($Y1star{$year});
   $Y2star{$year} = "&nbsp;" unless ($Y2star{$year});
   $Y3star{$year} = "&nbsp;" unless ($Y3star{$year});
   $Y4star{$year} = "&nbsp;" unless ($Y4star{$year});
   $Y5star{$year} = "&nbsp;" unless ($Y5star{$year});
   $Y6star{$year} = "&nbsp;" unless ($Y6star{$year});
   $Y7star{$year} = "&nbsp;" unless ($Y7star{$year});
   $Y8star{$year} = "&nbsp;" unless ($Y8star{$year});
   $Y9star{$year} = "&nbsp;" unless ($Y9star{$year});
   $Ylead{$year} = "&nbsp;" unless ($Ylead{$year});
   $Ysec{$year} = "&nbsp;" unless ($Ysec{$year});
   $Ysport{$year} = "&nbsp;" unless ($Ysport{$year});
   $Yepoints{$year} = "&nbsp;" unless ($Yepoints{$year});

   $s .= "<tr><td><b>";
   $s .= $year;
   $s .= "-" unless ($year);
   $s .= "</b></td><td>$Yroutes{$year}</td>";
#   $s .= sprintf "<td>%dm</td>", $Yheight{$year} / 3;
   $s .= "<td>$Y1star{$year}</td>";
#   $s .= "<td>$Y2star{$year}</td>";
   $s .= "<td>$Y3star{$year}</td>";
#   $s .= "<td>$Y4star{$year}</td>";
#   $s .= "<td>$Y5star{$year}</td>";
#   $s .= "<td>$Y6star{$year}</td>";
#   $s .= "<td>$Y7star{$year}</td>";
#   $s .= "<td>$Y8star{$year}</td>";
#   $s .= "<td>$Y9star{$year}</td>";
   $s .= "<td><a href=\"$theinit-date.html#$YDlead{$year}\">$Ylead{$year}</a></td>";
#   $s .= "<td><a href=\"$theinit-date.html#$YDsec{$year}\">$Ysec{$year}</a></td>";
#   $s .= "<td><a href=\"$theinit-date.html#$YDsport{$year}\">$Ysport{$year}</a></td>";
   $s .= "<td>$Yepoints{$year}</td></tr>";

   $Xroutes += $Yroutes{$year};
   $Xheight += $Yheight{$year};
   $X1star += $Y1star{$year};
   $X2star += $Y2star{$year};
   $X3star += $Y3star{$year};
   $X4star += $Y4star{$year};
   $X5star += $Y5star{$year};
   $X6star += $Y6star{$year};
   $X7star += $Y7star{$year};
   $X8star += $Y8star{$year};
   $X9star += $Y9star{$year};
}
$s .= "<tr><td><i>Total</i></td><td>";
$s .= sprintf "<i>$Xroutes</i></td></tr>\n";
$s .= "</table>\n\n";
$stats{$theinit} = $s;


}#sub generate


sub index {
  # Write index file
  open(IN, "$src/index-frame.html");
  open(OUT, "> $dest/index.html");
  while (<IN>) {
    if (/\{LATEST (.)\}/) {
      print OUT $latest{"$1w"};
    } elsif (/\{STATS (.)\}/) {
      print OUT $stats{"$1w"};
    } elsif (/\{DATE (.)\}/) {
      $d = $latestdate{"$1w"};
      s/\{DATE (.)\}/$d/g;
      print OUT;
    } else {
      print OUT;
    }
  }
  close(INDEX);
  close(IN);
}


######### main

print "<p>\n<pre>\n" if ($cgi);

# &generate('fw');
&generate('mw');
&index;

# Done!
print "Done.\n";
if ($cgi) {
    print "</pre>\n";
    print "<a href=\"/ext/climbing/climbs/\">\n";
    print "Have a look at the updated pages</a>";
}
