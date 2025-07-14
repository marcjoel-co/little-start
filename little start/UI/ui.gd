extends CanvasLayer

var stage = 1

func progress_growth(value):
	$ProgressBar.value += value
	if $ProgressBar.value >= 100:
		$ProgressBar.value = 0
		progress_stage(1)

func progress_stage(value):
	stage += value
	$"Growth Stage".text = "Growth Stage: " + str(stage)
