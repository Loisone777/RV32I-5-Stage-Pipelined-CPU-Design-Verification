# RV32I multi-seed constrained pseudo-random regression

set seeds {
    32'h20260702
    32'h00000001
    32'h00000011
    32'h12345678
    32'h5A5A2026
}

puts "================================================"
puts " RV32I RANDOM REGRESSION START"
puts "================================================"

foreach seed $seeds {

    puts ""
    puts "------------------------------------------------"
    puts " Running seed: $seed"
    puts "------------------------------------------------"

    set_property generic \
        "RUN_RANDOM=1 RANDOM_SEED=$seed RANDOM_BODY_LEN=80" \
        [get_filesets sim_1]

    launch_simulation -mode behavioral -simset sim_1
    run 2 us
    close_sim
}

puts ""
puts "================================================"
puts " RV32I RANDOM REGRESSION FINISHED"
puts "================================================"