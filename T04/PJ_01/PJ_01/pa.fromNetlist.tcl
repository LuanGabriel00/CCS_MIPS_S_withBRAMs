
# PlanAhead Launch Script for Post-Synthesis floorplanning, created by Project Navigator

create_project -name PJ_01 -dir "/home/ise/ise_projs/T04/PJ - 01/PJ_01/planAhead_run_1" -part xc3s1200efg320-4
set_property design_mode GateLvl [get_property srcset [current_run -impl]]
set_property edif_top_file "/home/ise/ise_projs/T04/PJ - 01/PJ_01/MIPS_S_withBRAMs.ngc" [ get_property srcset [ current_run ] ]
add_files -norecurse { {/home/ise/ise_projs/T04/PJ - 01/PJ_01} }
set_property target_constrs_file "MIPS_S_withBRAMs.ucf" [current_fileset -constrset]
add_files [list {MIPS_S_withBRAMs.ucf}] -fileset [get_property constrset [current_run]]
link_design
