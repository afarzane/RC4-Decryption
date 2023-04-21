restart -f

force -freeze sim:/lcd/KEY 1000 0
force -freeze sim:/lcd/CLOCK_50 1 0, 0 {50 ps} -r 100
force -freeze sim:/lcd/lcd_start 1 0