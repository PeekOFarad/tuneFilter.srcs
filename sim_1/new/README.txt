Postup pro práci:

CELÝ POSTUP PROVÁDĚT VE SLOŽCE tuneFilter.srcs\sim_1\new (dál pracovní složka - PS)

1. Otevřít my_filter_session.fda v programu filterDesigner (Open session)
2. Zvolit mezní kmitočet (popř. řád, potom je potřeba přepsat řád v tuneFilter_pkg.vhd)
3. Exportovat do MATLAB workspace (Export as coefficients), ve workspace musí vzniknout SOS a G
4. Generate HDL (mimo PS) -> pod Test Bench\Configuration zvolit Multi-file test bench
5. Vzniklý soubor filter_tb_data.vhd přesunout do PS
6. Nastavit jméno souboru ve skriptu generateCFG.m spustit
7. Nastavit jména souborů ve skriptu get_test_vector.m spustit
8. V tc_master_bfm_smoke_test.vhd vložit jména souborů z kroků 6 a 7
9. Spustit sim. na tak dlouho, než se v konzoli objeví hlášení o výsledku (1.2 ms pro 4 sekce)
10. Nastavit jméno souboru ve skriptu compare_results.m a spustit

