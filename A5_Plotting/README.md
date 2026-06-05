This directory contains code written to generate most of the figures presented in the Burstiness paper (some figures are generated using scripts in `A2_DataSummaryAnalyses`. The `README` in the relevant directory highlights these instances).

`Fig1_MainTxt_AndAssociatedSIFigs.m` generates the non-schematic portions of Fig. 1 in the main text + Supplementary Figs. S23-S26.

`Fig2_MainTxt_PrevStSiBeta.m` generates Fig. 2 in the main text. Requires `DrawLineAndPatchForCI.m` and `GetPrevStSiEffFig.m`.

`Fig3_MainTxtAndAssociatedSuppFigs_RespBeta.m` generates Fig 3 in the main text + Supplementary Figs. S30 and S31. Requires `GetRespBetaFigs.m` and `GetRespBetaFigs_SI.m`.

`SI_FigS1_DataSummary_AgeDistributionPlots.m` generates supplementary figure S1.

`SI_FigS2_LdaySegsDurAndNumsSummarywErrBars_ChnAd0IviMerged.m` generates supplementary figure S2.

`SI_FigS3_ValdataSegsDurAndNumsSummarywErrBars_ChnAd0IviMerged.m` generates supplementary figure S3.

`SI_FigS4_DataSummary_TotVocNumsAndDur.m` generates supplementary figure S4.

`SI_FigS5_S7_LdayDurAndNumsRecDayTotsSummary_ChnAd0IviMerged.m` generates supplementary figures S5 and S7.

`SI_FigS6_S8_ValDataDurAndNumsRecDayTotsSummary_ChnAd0IviMerged.m` generates supplementary figures S6 and S8.

`SI_ReliabilitySummaryTabAndPlots.m` generates supplementary figures S19 and S20. 

`SI_IEiAndDurDistPlots_LENA.m` generates supplementary figures S9, S11, S13, and S15. Requires `GetUttDurations.m`.

`SI_IEiAndDurDistPlots_ValData.m` generates supplementary figures S10, S12, S14, and S16. Requires `GetUttDurations.m`.

For more specific details, please read comments about paths and other notes in the files before executing them.
