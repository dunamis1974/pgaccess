# contributed by Bret Green

proc newGraph {g} {
	catch "namespace forget Graph($g)"
	namespace eval Graph($g) "
		variable type \"line\"
		variable title \"Graph 1\"
		variable ymin 0
		variable ymax 100
		variable numYIntervals 10
		variable ytitle \"\"
		variable xtitle \"\"
		variable xlabels {}
		variable labelGap 5
		variable dataSeries
		variable dataSeriesColor
		variable lineWidth 2
		variable xsize 400
		variable ysize 300
		variable markerSize 6
		variable tickSize 5
		variable leftMargin 50
		variable rightMargin 20
		variable header 50
		variable footer 60
		variable barGap {10 3}

		proc cleardataSeries {} {
			variable dataSeries
			foreach i \[array name dataSeries\] {
				unset dataSeries(\$i)
			}
		}

		proc calcy {series index} {
			variable ysize
			variable footer
			variable dataSeries
			variable ymax
			variable ymin
			variable ysize
			variable header

			set res \[expr \"\$ysize - \$footer - (\[lindex \$dataSeries(\$series) \$index\] - \$ymin) * (\$ysize - \$footer - \$header) / (\$ymax - \$ymin)\"\]
			if {\$res < \[expr \$ysize-\$footer\]} {
				return \$res
			} else {
				return \[expr \$ysize-\$footer\]
			}
		}

		proc draw {{xpos 0} {ypos 0}} {
			variable type
			variable title
			variable ymin
			variable ymax
			variable numYIntervals
			variable xtitle
			variable ytitle
			variable xlabels
			variable labelGap
			variable dataSeries
			variable dataSeriesColor
			variable lineWidth
			variable xsize
			variable ysize
			variable markerSize
			variable tickSize
			variable leftMargin
			variable rightMargin
			variable header
			variable footer
			variable barGap

			catch \"destroy $g\"

			canvas $g -width \$xsize -height \$ysize
			place $g -x \$xpos -y \$ypos

			# title
			$g create text \[expr \$xsize/2\] \[expr \$header/2\] -text \$title

			# x title
			$g create text \[expr \$leftMargin+(\$xsize-\$leftMargin-\$rightMargin)/2\] \[expr \$ysize-(\$footer-\$tickSize-5)/2\] -text \$xtitle -anchor n

			# axes
			$g create line \$leftMargin \$header \$leftMargin \[expr \$ysize-\$footer\] -width \$lineWidth
			$g create line \$leftMargin \[expr \$ysize-\$footer\] \[expr \$xsize-\$rightMargin\] \[expr \$ysize-\$footer\] -width \$lineWidth

			for {set i 0} {\$i <= \$numYIntervals} {incr i} {
				set y \[expr \"\$header + \$i*(\$ysize - \$header - \$footer)/\$numYIntervals\"\]

				# vertical ticks
				$g create line \[expr \$leftMargin-\$tickSize\] \$y \$leftMargin \$y -width \$lineWidth

				# vertical labels
				$g create text \[expr \$leftMargin-\$tickSize-5\] \$y -anchor e -text \[expr \$ymax-(\$ymax-\$ymin)*\$i/\$numYIntervals\]
			}

			if {\$type == \"line\"} {
				set names \[array name dataSeries\]
				set numXVals \[llength \$dataSeries(\[lindex \$names 0\])\]

				for {set i 0} {\$i < \$numXVals} {incr i} {
					if {\$numXVals > 1} {
						set x \[expr \"\$leftMargin + \$i*(\$xsize - \$leftMargin - \$rightMargin)/(\$numXVals - 1)\"\]
					} else {
						set x \[expr \"(\$xsize - \$leftMargin - \$rightMargin) / 2 + \$leftMargin\"\]
					}

					# horizontal ticks
					$g create line \$x \[expr \$ysize-\$footer\] \$x \[expr \$ysize-\$footer+\$tickSize\] -width \$lineWidth

					# x axis labels
					if {\[llength \$xlabels\] >= \$numXVals} {
						$g create text \$x \[expr \$ysize-\$footer+\$tickSize+5\] -anchor n -text \[lindex \$xlabels \$i\]
					}
				}

				foreach series \[array name dataSeries\] {
					if {\[llength \$dataSeriesColor(\$series)\] < 4} {
						for {set i \[expr \[llength \$dataSeriesColor(\$series)\]+1\]} {\$i <= 4} {incr i} {
							lappend dataSeriesColor(\$series) \[lindex \$dataSeriesColor(\$series) 0\]
						}
					}

					for {set i 0} {\$i < \[llength \$dataSeries(\$series)\]} {incr i} {
						if {\[llength \$dataSeries(\$series)\] > 1} {
							set x \[expr \"\$leftMargin + \$i*(\$xsize - \$leftMargin - \$rightMargin)/(\[llength \$dataSeries(\$series)\] - 1)\"\]
						} else {
							set x \[expr \"(\$xsize - \$leftMargin - \$rightMargin) / 2 + \$leftMargin\"\]
						}

						# data points
						if {\$i > 0} {
							if {\[lindex \$dataSeries(\$series) \$i\] > \[lindex \$dataSeries(\$series) \[expr \$i-1\]\]} {
								$g create line \$lastx \[calcy \$series \[expr \$i-1\]\] \$x \[calcy \$series \$i\] -width \$lineWidth -fill \[lindex \$dataSeriesColor(\$series) 0\]
							} elseif {\[lindex \$dataSeries(\$series) \$i\] == \[lindex \$dataSeries(\$series) \[expr \$i-1\]\]} {
								$g create line \$lastx \[calcy \$series \[expr \$i-1\]\] \$x \[calcy \$series \$i\] -width \$lineWidth -fill \[lindex \$dataSeriesColor(\$series) 1\]
							} else {
								$g create line \$lastx \[calcy \$series \[expr \$i-1\]\] \$x \[calcy \$series \$i\] -width \$lineWidth -fill \[lindex \$dataSeriesColor(\$series) 2\]
							}
						}

						set lastx \$x
					}

					# point markers
					for {set i 0} {\$i < \[llength \$dataSeries(\$series)\]} {incr i} {
						if {\[llength \$dataSeries(\$series)\] > 1} {
							set x \[expr \"\$leftMargin + \$i*(\$xsize - \$leftMargin - \$rightMargin)/(\[llength \$dataSeries(\$series)\] - 1)\"\]
						} else {
							set x \[expr \"(\$xsize - \$leftMargin - \$rightMargin) / 2 + \$leftMargin\"\]
						}

						$g create oval \[expr \$x-\$markerSize/2\] \[expr \[calcy \$series \$i\]-\$markerSize/2\] \[expr \$x+\$markerSize/2\] \[expr \[calcy \$series \$i\]+\$markerSize/2\] \
							-fill \[lindex \$dataSeriesColor(\$series) 3\] -outline \[lindex \$dataSeriesColor(\$series) 3\]
					}
				}
			} else {
				# bar graph
				set names \[array name dataSeries\]
				set numXVals \[llength \$dataSeries(\[lindex \$names 0\])\]
				set xSpacing \[expr \"(\$xsize - \$leftMargin - \$rightMargin) / \$numXVals\"\]
				set barWidth \[expr \"(\$xSpacing - \[lindex \$barGap 0\] - (\[llength \$names\] - 1) * \[lindex \$barGap 1\]) / \[llength \$names\]\"\]
				set barSpacing \[expr \"\$barWidth +  \[lindex \$barGap 1\]\"\]

				for {set i 0} {\$i < \$numXVals} {incr i} {
					if {\$numXVals > 1} {
						set x \[expr \"\$leftMargin + \$xSpacing/2 + \$i*\$xSpacing\"\]
					} else {
						set x \[expr \"(\$xsize - \$leftMargin - \$rightMargin) / 2 + \$leftMargin\"\]
					}

					# horizontal ticks
					$g create line \$x \[expr \$ysize-\$footer\] \$x \[expr \$ysize-\$footer+\$tickSize\] -width \$lineWidth

					# x axis labels
					if {\[llength \$xlabels\] >= \$numXVals} {
						$g create text \$x \[expr \$ysize-\$footer+\$tickSize+5\] -anchor n -text \[lindex \$xlabels \$i\]
					}

					# bars
					set j 0
					foreach series \[array name dataSeries\] {
						set xbar \[expr \"\$x - (\$xSpacing - \[lindex \$barGap 0\])/2 + \$j*\$barSpacing - 1\"\]
						$g create rectangle \$xbar \[calcy \$series \$i\] \[expr \$xbar+\$barWidth\] \[expr \$ysize-\$footer-1\] -fill \[lindex \$dataSeriesColor(\$series) 0\]
						incr j
					}
				}
			}
		}
	"
}

newGraph .g1
namespace eval Graph(.g1) {
	set type bar
	set title "New Pensioner Sign-ups"
	set xsize 400
	set ysize 400
	cleardataSeries
	set dataSeries(Enseleni) {10 30 90 60 60 20 40}
	set dataSeriesColor(Enseleni) blue
	set dataSeries(Matubatuba) {20 60 60 20 80 30 40}
	set dataSeriesColor(Matubatuba) red
	#set dataSeries(Westville) {10 20 30 40 50 60 70}
	#set dataSeriesColor(Westville) green
	#set dataSeries(Fred) {20 18 100 54 61 9 11}
	#set dataSeriesColor(Fred) purple
	set xlabels {2/9 3/9 4/9 5/9 6/9 9/9 10/9}
	set xtitle "Start date: 02/09/2002       End date: 10/09/2002"
	draw 50 50
}

newGraph .g2
namespace eval Graph(.g2) {
	set type line
	set title "New Pensioner Sign-ups"
	set xsize 400
	set ysize 400
	cleardataSeries
	set dataSeries(Enseleni) {10 30 90 60 60 20 40}
	set dataSeriesColor(Enseleni) blue
	set dataSeries(Matubatuba) {20 60 60 20 80 30 40}
	set dataSeriesColor(Matubatuba) red
	set dataSeries(Westville) {10 20 30 40 50 60 70}
	set dataSeriesColor(Westville) green
	set dataSeries(Fred) {20 18 100 54 61 9 11}
	set dataSeriesColor(Fred) purple
	set xlabels {2/9 3/9 4/9 5/9 6/9 9/9 10/9}
	set xtitle "Start date: 02/09/2002       End date: 10/09/2002"
	draw 450 50
}

