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
# Author:   Frederik Willerup 
# Created:  January 1997
# Modified: January 2022 (mw) mathias@willerup.com
#

# require("extenv.pl");

# Some constants that depend on the platform we run on
$thedate = `date +"%e %B %y"`;
$src = ".";
$dest = "./html";

# Color constants
$Chead = "";
$Cbody = 'class="q"';
@Cbody = ("#e6e6e6","#eaeaea","#eeeeee","#f2f2f2","#f6f6f6","#fafafa");
@Ctext = ("#000000","#444444","#777777","#999999","#bbbbbb","#d8d8d8");
$Ccomment = "";

$Istar1 = '&#129482;'; #ice
$Istar2 = '&#127956;'; #mount
$Istar3 = '&#128371;';  #cave 

# Some table formatting
$Hstars = "";
$Hdate = "";
$Hname = "";
$Harea = "";
$Hpeople = "";
$Hgrade = "";
$Hheight = "";
$Hicons =  "";

$Tstars = ' ';
$Tstars1 = '/';
$Tdate = ' ';
$Tdate1 = '/';
$Tname = ' ';
$Tname1 = '/';
$Tarea = ' ';
$Tarea1 = '/';
$Tpeople = ' ';
$Tpeople1 = '/';
$Tgrade = ' '; #'<td>';
$Tgrade1 = '/'; #'</td>';
$Theight = ' ';
$Theight1 = '/';
$Ticons =  ' '; #'<td style="padding: 0px 0px 0px 4px">'
$Ticons1 = '/';

$Ttable = '';


# Global Routines and things
@months = ('January','February','March','April','May','June','July',
           'August','September','October','November','December');
%ukadj = ('D',200,'VD',400,'HVD',450,'S',500,'HS',600,'VS',700,'HVS',850,'E1',1000,'E2',1060,'E3',1100,'E4',1125,'E5',1200,'E6',1280,'E7',1300);
%post = ('a',0,'b',25,'c',50,'d',75);
%french = ('III',600,'F3',600,'IV',750,'F4',750,'F5',900,'V',900,'F6a',1020,'F6b',1085,'F6c',1100,'F7a',1180,'F7b',1250,'F7c',1300);
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
local(%Yroutes,%Yheight,%Y3star,%Ylead,%Ysec,%Ysport,%Yepoints);
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
	  $stars = "&nbsp;";
	  $stars = $Istar1 if ($nstars == 1);
	  $stars = $Istar2 if ($nstars == 2);
	  $stars = $Istar3 if ($nstars == 3);

        ($date,$area,$name,$grade,$height,$people,$icons) = split(';');

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
        $height = '&nbsp;' unless ($height);

        # Icons
        $i1 = '<img src='; # '<img src=';
        $i2 = ' height=18>'; # ' height=18>';
	$mind = $icons =~ /<M>/;
        $icons =~ s/<E>/$i1"img\/heart.gif" alt="Scary" width=18$i2/g; 
        $icons =~ s/<I>/&#129482;/g;
        $icons =~ s/<1S>/*/g;
        $icons =~ s/<2S>/**/g;
        $icons =~ s/<3S>/***/g;
        #$icons =~ s/<I>/$i1"img\/ice.gif" alt="Ice" width=18$i2/g;
        $icons =~ s/<Q>/$i1"img\/bail.gif" alt="Bail" width=24$i2/g;
        #$icons =~ s/<C>/$i1"img\/cave.gif" alt="Cave" width=15 height=15>/g;
        $icons =~ s/<C1>/$i1"img\/A.gif" alt="Cave beginner" width=18$i2/g;
        $icons =~ s/<C2>/$i1"img\/B.gif" alt="Cave challenge" width=18$i2/g;
        $icons =~ s/<C3>/$i1"img\/C.gif" alt="Cave intermediate" width=18$i2/g;
        $icons =~ s/<C4>/$i1"img\/D.gif" alt="Cave expert" width=18$i2/g;
        $icons =~ s/<S>/$i1"img\/arm.gif" alt="Streneous" width=16$i2/g;
        # $icons =~ s/<T>/$i1"img\/technical.gif" alt="Technical" width=12$i2/g;
        # $icons =~ s/<L>/$i1"img\/loose.gif" alt="Loose" width=11$i2/g;
        $icons =~ s/<W>/$i1"img\/whipper.gif" alt="Whipper" width=36$i2/g;
        # $icons =~ s/<P>/$i1"img\/polished.gif" alt="Polished" width=10$i2/g;
        $icons =~ s/<B>/$i1"img\/bolted.gif" alt="Bolted" width=18$i2/g;
        # $icons =~ s/<V>/$i1"img\/vegetabled.gif" alt="Vegetabled" width=11$i2/g;
        $icons =~ s/<M>/&#127798;/g;
        # $icons =~ s/<R>/$i1"img\/runout.gif" alt="Runout" width=10$i2/g;
        $icons =~ s/<N ([^\>]*)>/<a href="\1">$i1"img\/note.gif" border=0 alt="Note" width=18$i2<\/a>/g;
        $icons =~ s/<P ([^\>]*)>/<a href="\1">$i1"img\/photo.gif" border=0 alt="Photo" width=18$i2<\/a>/g;

        #$icons = sprintf("<%d>",$nstars) . $icons if ($nstars && !($icons =~ /<\d>/));
        #$icons =~ s/<1>/$Istar1/g;
        #$icons =~ s/<2>/$Istar2/g;
        #$icons =~ s/<3>/$Istar3/g;
        $icons =~ s/<\d>//g;

        $icons = '&nbsp;' if ($icons =~ /^\s*$/);

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
            $date = "&nbsp;";
        }
        $d =~ s/1$/1/;
        $d =~ s/2$/2/;
        $d =~ s/3$/3/;
        $d =~ s/([04-9])$/\1/;
        $d =~ s/(1[0-9])../\1/;
	  $cdate{$ndate} .= "|" if ($cdate{$ndate});
        $cdate{$ndate} .= "$sdate~$d~$name~$sarea~$grade~$height~$speople~$icons~$stars~";

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
	  $Y3star{$y}++ if ($nstars == 3);
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
    }
}
close(CLIMBS);



# Output: write the files
open(IN, "$src/frame.html") || die "error: failed to open $src/climbs-frame.html";
open(AREA, "> $dest/$theinit-area.html") || die "error: failed to open $dest/$theinit-area.html";
open(DATE, "> $dest/$theinit-date.html") || die "error: failed to open $dest/$theinit-date.html";
open(PEOPLE, "> $dest/$theinit-people.html") || die "error: failed to open $dest/$theinit-people.html";
open(STARS, "> $dest/$theinit-quality.html") || die "error: failed to open $dest/$theinit-quality.html";
open(GRADE, "> $dest/$theinit-grade.html") || die "error: failed to open $dest/$theinit-grade.html";

while (<IN>) {
    s/\{I\}/$theinit/g;
    s/\{DATE\}/$thedate/g;
    s/\{SORT\}/x/g;
    s/\{NAME\}/$thename/g;
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
                $output .= "<div class=name>$name <span class=grade>$grade $icons</span> <span class=tiny> / $date</span></div>";
                $output .= "<div class=details>$height / $people</div> \n ";
                if ($comment) {
                    $output .= "<div class=comment>$comment</div>\n";
                }

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
        print AREA "<hr class=grey><h2>Area index</h2><table>\n";
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
            $title = "Not dated (before 1995)" if ($sdate == 0);

            print DATE "<h2><a name=\"$sdate\">$title</a></h2>\n";
            print DATE "";
            print DATE "$Hdate" if ($sdate > 0);
            print DATE "\n";

            foreach (sort {$b<=>$a} split('\|', $cdate{$sdate})) {
                ($x,$date,$name,$area,$grade,$height,$people,$icons,$stars,$comment) = split('\~');
                print DATE "<hr class=grey>";
                print DATE "<div class=name>$name <span class=grade>$grade $icons</span></div>";
                print DATE "<div class=details>$area / $height / $people / $stars</div>";
                if ($comment) {
                  print DATE "<div class=comment>$comment</div>";
                }
                

            }
            print DATE "\n\n";
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
                ($x,$date,$name,$area,$grade,$height,$people,$icons,$stars) = split('~');
                $output .= "<hr class=grey><div class=name>$date: $name, $area</a></div>";

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
        print PEOPLE "<hr class=grey><h2>Climbing Partners</h2><table>\n";
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
        foreach $stars(sort {$b<=>$a} keys %cstars) {
            @stars = ("Ice climbs $Istar1", "Mountains $Istar2", "Caves $Istar3");
            printf STARS "<h2>%s</h2>\n", $stars[$stars-1];
            print STARS "";
            print STARS "";

            foreach (sort {$b<=>$a} split('\|', $cstars{$stars})) {
                ($x,$date,$name,$area,$grade,$height,$people,$icons,$s,$comment) = split('~');
                print STARS "<hr class=grey>";
                print STARS "<div class=name>$name <span class=grade>$grade </span></div>";
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
           $output .= "<h2>$sys Graded Climbs</h2>\n";
           $output .= "";
           $output .= "";
           %list = ();
           foreach (sort {$b<=>$a} split('\|', $cgrade{$sys})) {
               ($x,$date,$name,$area,$grade,$height,$people,$icons,$stars,$comment) = split('~');
               $g = &basegrade($grade);
               $g =~ s/\s\S*$//;
               $list{$g}++;                   

               $output .= "<hr class=grey><div class=name>$name <span class=grade>$grade</span>, $area</a></div>";
               $output .= "<div class=details>$height / $people / $icons / $stars / $date</div>\n";
           }
           $output .= "\n\n";

####### table of number of routes in each grade
#	     print GRADE "<table><tr><td>Grade</td><td>Routes</td></tr>\n";
#	     foreach $g(keys %list) {
#		 print GRADE "<tr><td>$g</td><td>$list{$g}</td></tr>\n";
#           }
#           print GRADE "</table>\n\n";

	     print GRADE $output;
      }
        
    } else {
        print AREA;
        print DATE;
        print PEOPLE;
        print STARS;
        print GRADE;
    }
}
close(IN);
close(AREA);
close(DATE);
close(PEOPLE);
close(STARS);
close(GRADE);

###### Generate the "statistics" section
$Xroutes = 0, $Xheight = 0, $X3star = 0;
$s = "<table width=100%>\n<tr $Chead><td align=center>Year</td>";
$s .= "<td align=center>Routes</td>";
$s .= "<td align=center>$Istar3</td><td align=center>Trad</td>";
$s .= "<td align=center>Sport</td><td align=center>Epts</td></tr>\n";
foreach $year(sort {$b<=>$a} keys %Yroutes) {
   $Yroutes{$year} = "&nbsp;" unless ($Yroutes{$year});
   $Yheight{$year} = "&nbsp;" unless ($Yheight{$year});
   $Y3star{$year} = "&nbsp;" unless ($Y3star{$year});
   $Ylead{$year} = "&nbsp;" unless ($Ylead{$year});
   $Ysec{$year} = "&nbsp;" unless ($Ysec{$year});
   $Ysport{$year} = "&nbsp;" unless ($Ysport{$year});
   $Yepoints{$year} = "&nbsp;" unless ($Yepoints{$year});

   $s .= "<tr $Cbody><td align=center><b>";
   $s .= $year;
   $s .= "-" unless ($year);
   $s .= "</b></td><td align=center>$Yroutes{$year}</td>";
#   $s .= sprintf "<td align=right>%dm</td>", $Yheight{$year} / 3;
   $s .= "<td align=center>$Y3star{$year}</td>";
   $s .= "<td align=center><a href=\"$theinit-date.html#$YDlead{$year}\">$Ylead{$year}</a></td>";
#   $s .= "<td><a href=\"$theinit-date.html#$YDsec{$year}\">$Ysec{$year}</a></td>";
   $s .= "<td align=center><a href=\"$theinit-date.html#$YDsport{$year}\">$Ysport{$year}</a></td>";
   $s .= "<td align=center>$Yepoints{$year}</td></tr>";

   $Xroutes += $Yroutes{$year};
   $Xheight += $Yheight{$year};
   $X3star += $Y3star{$year};
}
$s .= "<tr><td align=center><i>Total</i></td><td align=center>";
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




