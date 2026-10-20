-- repro for the DXMT viewport hang: create a mesh and force redraws
b = box length:40 width:40 height:40
completeRedraw()
for i = 1 to 20 do (rotate b (angleaxis 5 [0,0,1]); completeRedraw())
format "drawbox.ms done\n"
