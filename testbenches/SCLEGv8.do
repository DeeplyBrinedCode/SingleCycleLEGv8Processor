force clk 0 0ns, 1 10ns -r 20ns
force reset 1
run 20ns
force reset 0
run 1000ns
