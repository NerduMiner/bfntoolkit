for %%a in ("./*.png") do (
wimgt encode %%a -d %%~pa%%~na.bti -x BTI.IA4 --n-mm=0
)