-- repro for viewport stream-output paths: smooth, flat and textured objects, shading modes, selection
fn step msg = (completeRedraw(); format "objects.ms: %\n" msg)
s = sphere radius:20 pos:[-40,0,0]; step "sphere"
t = teapot radius:15 pos:[40,0,0]; step "teapot"
viewport.SetRenderLevel #wireframe; step "wireframe"
viewport.SetRenderLevel #smoothhighlights; step "shaded"
select s; step "select sphere"
b = box length:30 width:30 height:30 pos:[0,40,0]; step "box"
select b; step "select box"
format "objects.ms done\n"
