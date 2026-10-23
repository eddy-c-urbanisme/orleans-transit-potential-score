-- ÉTAPE 2.4 : Agrégation spatiale (Fusion en 117 IRIS)
DROP TABLE IF EXISTS SCORE_IRIS_ORLEANS;

CREATE TABLE SCORE_IRIS_ORLEANS AS
SELECT
    -- 1. Identification géographique du quartier
    iris.Code_Iris AS CODE_IRIS,      -- Indispensable pour la jointure cartographique sous QGIS
    iris.lib_com AS NOM_COMMUNE,
    iris.lib_iris AS NOM_IRIS,
    iris.type_iris AS TYPE_IRIS,      -- (Optionnel : H=Habitat, A=Activité, D=Divers, Z=Non-irisé)

    -- 2. Données démographiques arrondies à l'entier (0 décimale) pour les visuels Power BI
    ROUND(pop.P22_POP, 0) AS POP_TOTALE,
    ROUND(pop.P22_POP1117, 0) AS POP_11_17_ANS,
    ROUND(pop.P22_POP1824, 0) AS POP_18_24_ANS,
    ROUND(pop.P22_POP65P, 0) AS POP_65_ANS_PLUS,
    ROUND(pop.C22_POP15P_STAT_GSEC16_26, 0) AS POP_OUVRIERS,
    ROUND(pop.C22_POP15P_STAT_GSEC40, 0) AS POP_SANS_ACTIVITE,

    -- 3. Nombre total d'équipements présents dans le quartier
    COUNT(bpe.TYPEQU) AS NB_EQUIPEMENTS,

    -- 4. Les 3 Scores Bruts (IFNULL remplace le vide par 0 si un quartier n'a aucun équipement)
    IFNULL(pop.score_pop, 0) AS SCORE_EMETTEUR_BRUT,
    IFNULL(SUM(bpe.score_bpe), 0) AS SCORE_RECEPTEUR_BRUT,
    IFNULL(pop.score_pop, 0) + IFNULL(SUM(bpe.score_bpe), 0) AS SCORE_TPS_GLOBAL_BRUT

FROM REF_IRIS_ORLEANS AS iris
LEFT JOIN POP_ORLEANS_TPS AS pop
    ON iris.Code_Iris = pop.IRIS
LEFT JOIN BPE_ORLEANS_TPS AS bpe
    ON iris.Code_Iris = bpe.DCIRIS
GROUP BY iris.Code_Iris
ORDER BY SCORE_TPS_GLOBAL_BRUT DESC;
