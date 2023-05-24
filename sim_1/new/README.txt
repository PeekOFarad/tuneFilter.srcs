Postup pro práci:

CELÝ POSTUP PROVÁDĚT VE SLOŽCE tuneFilter.srcs\sim_1\new (dál pracovní složka - PS)

Prefixy:
Pro rozlišení souborů a usnadnění verifikace mají soubory dané prefixy.

"cfg_" - konfigurační soubor s koeficienty
"test_vectors_" - soubor s testovacími, referenčními daty a jejich velikostí
"result_of_" - soubor s výstupními daty

Při verifikaci bylo použito následujícího syntaxu pro indentifikaci instancí filtru:

typ: LP, HP, BP, BS
mezní kmitočet: wXX (00 - 10 -> 0.0 - 1.0) nebo wXX_YY pro BP a BS
řád: oX

příklad pásmové propusti 8. řádu s mezními kmitočty 0.4 - 0.6: BP_w04_06_o8

1. Otevřít my_filter_session.fda v programu filterDesigner (Open session)
2. Zvolit mezní kmitočet (popř. řád, potom je potřeba přepsat řád v tuneFilter_pkg.vhd)
3. Exportovat do MATLAB workspace (Export as coefficients), ve workspace musí vzniknout SOS a G
4. Generate HDL (mimo PS) -> pod Test Bench\Configuration zvolit Multi-file test bench
5. Vzniklý soubor filter_tb_XXX_data.vhd přesunout do PS (XXX je identifikační postfix instance)
6. Nastavit jméno souboru ve skriptu generate_config.m spustit ("cfg_" & jméno)
7. Nastavit jména souborů ve skriptu get_test_vector.m spustit ("test_vectors_" & jméno)
8. V tc_master_bfm_smoke_test.vhd vložit jména souborů z kroků 6 a 7 (pouze jméno)
9. Spustit simulaci na tak dlouho, než se v konzoli objeví hlášení o výsledku
    (~1.2 ms pro 4 sekce, jeden test)
10. Nastavit jméno souboru ve skriptu compare_results.m a spustit
    ("result_of_""test_vectors_" & jméno)